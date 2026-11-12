import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/backend/financing.dart';
import '/backend/schema/structs/index.dart';
import '/core_ui/core_ui.dart';

class ProposalItemDraft {
  const ProposalItemDraft({
    required this.name,
    required this.quantity,
    required this.price,
    this.catalogId,
    this.savedId,
    this.discount = 0,
  });

  factory ProposalItemDraft.fromSaved(ProposalOptionalItemsStruct row) =>
      ProposalItemDraft(
        savedId: row.id,
        catalogId: row.hasAircraftItemId() ? row.aircraftItemId : null,
        name: row.item.itemName,
        quantity: row.item.qty,
        price: row.unitPrice ?? row.item.price,
        discount: row.discountPercent,
      );

  final String name;
  final int quantity;
  final double price;
  final String? catalogId;
  final String? savedId;
  final double discount;

  double get total =>
      (price * (100 - discount)).roundToDouble() / 100 * quantity;

  Map<String, dynamic> toDatabase() => {
        if (catalogId != null) 'aircraft_item_id': catalogId,
        if (catalogId == null) ...{
          'manual_name': name,
          'quantity': quantity,
          'unit_price': price,
        },
        'discount_percent': discount,
      };
}

class ProposalItemsEditor extends StatelessWidget {
  const ProposalItemsEditor({
    super.key,
    required this.items,
    this.onAdd,
    this.onEdit,
    this.canDiscount = false,
    this.onRemove,
  });

  final List<ProposalItemDraft> items;
  final VoidCallback? onAdd;
  final ValueChanged<ProposalItemDraft>? onEdit;
  final bool canDiscount;
  final ValueChanged<ProposalItemDraft>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && onAdd == null) return const SizedBox.shrink();
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'US$');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text('Itens da proposta',
                    style: Theme.of(context).textTheme.titleMedium),
                if (onAdd != null)
                  AppSecondaryButton(
                    label: 'Adicionar item manual',
                    icon: Icons.add_rounded,
                    onPressed: onAdd!,
                  ),
              ],
            ),
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text([
                  '${item.quantity} × ${money.format(item.price)}',
                  if (item.discount > 0)
                    '${proposalEntryLabel(item.discount / 100)} de desconto',
                  money.format(item.total),
                ].join(' · ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null &&
                        (item.catalogId == null || canDiscount))
                      IconButton(
                        tooltip: item.catalogId == null
                            ? 'Editar item'
                            : 'Editar desconto',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit!(item),
                      ),
                    if (onRemove != null)
                      IconButton(
                        tooltip: 'Remover item',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => onRemove!(item),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<ProposalItemDraft?> editProposalItem(
  BuildContext context, {
  ProposalItemDraft? item,
  required bool canDiscount,
}) =>
    showDialog<ProposalItemDraft>(
      context: context,
      builder: (_) => _ItemDialog(item: item, canDiscount: canDiscount),
    );

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({required this.item, required this.canDiscount});
  final ProposalItemDraft? item;
  final bool canDiscount;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _quantity =
      TextEditingController(text: (widget.item?.quantity ?? 1).toString());
  late final _price =
      TextEditingController(text: widget.item?.price.toString() ?? '0');
  late final _discount =
      TextEditingController(text: (widget.item?.discount ?? 0).toString());

  double? _decimal(String? value) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manual = widget.item?.catalogId == null;
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return AlertDialog(
      title: Text(manual ? 'Item manual' : 'Desconto do item'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!manual) Text(widget.item!.name),
              if (manual) ...[
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLength: 240,
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Informe a descrição.' : null,
                ),
                TextFormField(
                  controller: _quantity,
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final n = int.tryParse(value!.trim());
                    return n == null || n < 1 || n > 100000
                        ? 'Quantidade inválida.'
                        : null;
                  },
                ),
                TextFormField(
                  controller: _price,
                  decoration:
                      const InputDecoration(labelText: r'Preço unitário (US$)'),
                  keyboardType: decimal,
                  validator: (value) {
                    final n = _decimal(value);
                    return n == null || n < 0 || n >= 1e14
                        ? 'Valor inválido.'
                        : null;
                  },
                ),
              ],
              if (widget.canDiscount)
                TextFormField(
                  controller: _discount,
                  decoration: const InputDecoration(labelText: 'Desconto (%)'),
                  keyboardType: decimal,
                  validator: (value) {
                    final n = _decimal(value);
                    return n == null || n < 0 || n > 100
                        ? 'Use um valor de 0 a 100.'
                        : null;
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              ProposalItemDraft(
                savedId: widget.item?.savedId,
                catalogId: widget.item?.catalogId,
                name: _name.text.trim(),
                quantity: int.parse(_quantity.text.trim()),
                price: _decimal(_price.text)!,
                discount: widget.canDiscount
                    ? _decimal(_discount.text)!
                    : widget.item?.discount ?? 0,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
