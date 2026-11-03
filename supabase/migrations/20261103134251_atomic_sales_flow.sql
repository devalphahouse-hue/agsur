-- Each RPC is one transaction. Exceptions roll back every business write,
-- including the stock triggers. INVOKER preserves the existing table RLS.
create or replace function public.create_proposal_atomic(
  p_id uuid, p_lead_id uuid, p_aircraft_id uuid, p_stock_unit_id uuid,
  p_reference text, p_financing jsonb, p_optional_ids uuid[]
) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_existing public.proposal;
  v_rates public.financing_rates;
  v_price numeric;
  v_optional numeric;
  v_term integer := (p_financing->>'term_length')::integer;
  v_down numeric := (p_financing->>'down_payment')::numeric;
  v_initial numeric := (p_financing->>'initial_deposit')::numeric;
begin
  if auth.uid() is null or not public.auth_is_seller_or_admin() then
    raise exception 'Sem permissão para criar propostas.' using errcode='42501';
  end if;
  -- The client keeps this UUID across retries, even after a lost response.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_id::text, 0));
  select * into v_existing from public.proposal where id=p_id;
  if found then
    if v_existing.created_by is distinct from auth.uid()
       or v_existing.lead_id is distinct from p_lead_id
       or v_existing.aircraft_id is distinct from p_aircraft_id
       or v_existing.is_deleted
       or not exists(select 1 from public.proposal_financing where proposal_id=p_id) then
      raise exception 'Esta tentativa não corresponde a uma proposta completa. Atualize a página.';
    end if;
    return p_id;
  end if;
  if not exists(select 1 from public.leads where id=p_lead_id and active and not is_deleted) then
    raise exception 'Selecione um lead ativo antes de continuar.';
  end if;
  if v_term is null or v_term not in (5,7)
     or nullif(p_financing->>'credit_date','') is null
     or v_down is null or v_initial is null
     or v_down < 0 or v_initial < 0 or v_down+v_initial > 1 then
    raise exception 'Confira o prazo, a data e os percentuais do financiamento.';
  end if;
  select * into v_rates from public.financing_rates
    where id='ce659e4b-caee-4b88-8d99-46f15c7e9b69';
  if not found or v_rates.sofr_rate+v_rates.interest_rate <= 0 then
    raise exception 'Confira as taxas de financiamento antes de criar a proposta.';
  end if;
  select price into v_price from public.aircrafts
    where id=p_aircraft_id and not deleted;
  if not found then raise exception 'Selecione um modelo de aeronave disponível.'; end if;
  if exists(select 1 from unnest(p_optional_ids) as optional(id)
    where not exists(select 1 from public.aircraft_items i
      join public.aircraft_item_links l on l.aircraft_item_id=i.id
      where i.id=optional.id and l.aircraft_id=p_aircraft_id and i.active
        and not i.deleted and i.item_type::text='optional')) then
    raise exception 'Um dos opcionais não está disponível para esta aeronave.';
  end if;
  select coalesce(sum(price*qty),0) into v_optional from public.aircraft_items
    where id=any(coalesce(p_optional_ids,'{}'::uuid[]));
  insert into public.proposal(id,lead_id,aircraft_id,fullprice,created_by,available_aircraft_id,id_ref)
    values(p_id,p_lead_id,p_aircraft_id,v_price+v_optional,auth.uid(),p_stock_unit_id,p_reference);
  insert into public.proposal_financing(proposal_id,created_by,term_length,credit_date,
    down_payment,initial_deposit,total_deposit,premium_rate,sofr_rate,interest_rate)
    values(p_id,auth.uid(),v_term,(p_financing->>'credit_date')::date,
      v_down,v_initial,v_down+v_initial,
      case when v_term=5 then v_rates.premium_rate_five else v_rates.premium_rate_seven end,
      v_rates.sofr_rate,v_rates.interest_rate);
  insert into public.proposal_item(proposal_id,aircraft_item_id)
    select p_id,id from (select distinct unnest(p_optional_ids) id) items;
  return p_id;
end;
$$;

create or replace function public.convert_proposal_atomic(
  p_proposal_id uuid, p_email text, p_new_client_id uuid default null
) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare
  v_proposal public.proposal;
  v_lead public.leads;
  v_user public.users;
  v_contract uuid;
  v_aircraft uuid;
  v_sale uuid;
  v_created boolean := false;
  v_email text := lower(btrim(p_email));
begin
  if auth.uid() is null or not public.auth_is_seller_or_admin() then
    raise exception 'Sem permissão para converter propostas.' using errcode='42501';
  end if;
  select * into v_proposal from public.proposal where id=p_proposal_id for update;
  if not found or v_proposal.is_deleted or not v_proposal.active then
    raise exception 'Proposta não encontrada ou inativa.';
  end if;
  -- Serialize conversions of the same proposal. A retry returns the original.
  select id into v_contract from public.contract where proposal_id=p_proposal_id and cancelled_at is null;
  if found then
    if not v_proposal.is_contract then
      raise exception 'Existe um contrato anterior incompleto. Peça uma revisão ao administrador.';
    end if;
    return jsonb_build_object('contract_id',v_contract,'client_created',false);
  end if;
  if v_proposal.is_contract then raise exception 'Esta proposta já foi convertida.'; end if;
  if not exists(select 1 from public.proposal_financing where proposal_id=p_proposal_id) then
    raise exception 'A proposta está sem financiamento. Complete o cadastro antes de converter.';
  end if;
  select * into v_lead from public.leads where id=v_proposal.lead_id for update;
  if not found or v_lead.is_deleted then raise exception 'Lead não encontrado ou excluído.'; end if;
  if v_email is null or v_email='' or v_email is distinct from lower(btrim(v_lead.email)) then
    raise exception 'O e-mail do lead mudou. Confira o e-mail antes de converter.';
  end if;
  -- Different proposals can reuse the same client without racing its creation.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_email, 1));
  select * into v_user from public.users where lower(email)=v_email and not is_deleted for update;
  if found then
    if v_user.profile_type::text <> 'Cliente' then
      raise exception 'Este e-mail pertence a um usuário que não é cliente. Corrija o e-mail.';
    end if;
    if v_user.lead_id is not null and v_user.lead_id <> v_lead.id then
      raise exception 'Este e-mail pertence a um cliente vinculado a outro lead. Corrija o e-mail.';
    end if;
    if v_user.lead_id is null then
      update public.users set lead_id=v_lead.id where id=v_user.id;
      if not found then raise exception 'Sem permissão para vincular o cliente ao lead.' using errcode='42501'; end if;
    end if;
  else
    if p_new_client_id is null then raise exception 'Não foi possível criar o acesso do cliente. Tente novamente.'; end if;
    insert into public.users(id,name,lastname,fullname,email,phone,cpf,profile_type,is_admin,status,lead_id,profile_photo_url)
      values(p_new_client_id,v_lead.name,v_lead.last_name,v_lead.fullname,v_email,v_lead.phone,
        v_lead.cpf,'Cliente',false,'approved',v_lead.id,
        'https://bkzybtmxxzpxtztesdye.supabase.co/storage/v1/object/public/AGSur//user_icon%20(1).png')
      returning * into v_user;
    v_created := true;
  end if;
  insert into public.contract("user_Id",proposal_id,fullprice,created_by)
    values(v_user.id,p_proposal_id,v_proposal.fullprice,auth.uid()) returning id into v_contract;
  insert into public.user_aircraft(created_by,aircraft_status,proposal_id,contract_id)
    values(auth.uid(),'processing',p_proposal_id,v_contract) returning id into v_aircraft;
  insert into public.sales(seller_id,proposal_id,fullprice,seller_commission,company_commission,created_by)
    values(v_proposal.created_by,p_proposal_id,v_proposal.fullprice,
      case when coalesce(v_lead.is_referral,false) then 4500 else 7500 end,
      greatest(v_proposal.fullprice,0)*0.02,auth.uid()) returning id into v_sale;
  insert into public.financial(financial_type,sale_id,description,financial_status,created_by)
    values('income',v_sale,'Venda de aeronave','pending',auth.uid());
  insert into public.tracking(user_aircraft,tracking_description,"isCheck","order")
    select v_aircraft,description,false,(ordinality-1)::smallint from unnest(array[
      'Cadastro Inicial','Personalização da Aeronave','Solicitar Proforma Invoice',
      'Reservar Equipamento Agrícola Inox','Pagar Reserva','Pagamento 5%','Status Fiscal',
      'Contratação de Despachante Aduaneiro','Reserva de Marcas (RAB)','Formalização de Pagamento',
      'Aprovação de Crédito','Pré-contrato (Novo)','Contratação de Seguro','Apólices (Casco, LUC, RETA)',
      'Saldo de Entrada','Links de Acompanhamento','Documentação para Oficina',
      'Assinatura de Contrato Final','Documentação do Despachante','Desembaraço Aduaneiro','Liberação para Voo'
    ]) with ordinality as stages(description,ordinality);
  update public.proposal set is_contract=true where id=p_proposal_id;
  if not found then raise exception 'Sem permissão para concluir a conversão.' using errcode='42501'; end if;
  return jsonb_build_object('contract_id',v_contract,'client_created',v_created);
end;
$$;

revoke all on function public.create_proposal_atomic(uuid,uuid,uuid,uuid,text,jsonb,uuid[]) from public,anon;
revoke all on function public.convert_proposal_atomic(uuid,text,uuid) from public,anon;
grant execute on function public.create_proposal_atomic(uuid,uuid,uuid,uuid,text,jsonb,uuid[]) to authenticated;
grant execute on function public.convert_proposal_atomic(uuid,text,uuid) to authenticated;
