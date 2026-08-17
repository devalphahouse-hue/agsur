// Implementação para plataformas NÃO-web (Android/iOS/desktop).
//
// Existe só para o `abrir_pdf_gerado.dart` compilar fora do navegador:
// `package:web` é web-only e quebra o build mobile no kernel snapshot
// ("The getter 'toJS' isn't defined for the type 'String'"). O par
// io/web é escolhido pelo import condicional lá.
//
// Nunca é consultado de fato no mobile — o chamador só olha o WebKit
// quando `kIsWeb` é true —, mas precisa existir e compilar.
bool get ehWebKit => false;
