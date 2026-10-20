# SaldoCerto 1.3 — Android

Aplicativo de controle financeiro pessoal derivado da planilha original.

## Identidade visual
- Nome definitivo: **SaldoCerto**
- Pacote Android: `com.saldocerto.app`
- Paleta: verde petróleo `#006B5F`, azul ardósia `#284B63`, fundo `#F4F7F6`
- Ícone: carteira com check, representando contas organizadas e finanças em dia
- Splash screen nativa com o símbolo da marca

## O que já está no app
Dashboard mensal, receitas/despesas, contas pendentes, quinzenas, relatórios, recorrência, vencimentos, lembretes, edição/exclusão, projeção de saldo, backup/restauração e PIN/biometria.

## Gerar APK no computador
1. Instale Flutter estável e Android Studio/SDK.
2. Na pasta do projeto: `flutter pub get`
3. Verifique: `flutter doctor`
4. Gere: `flutter build apk --release`
5. APK: `build/app/outputs/flutter-apk/app-release.apk`

> Para publicação na Play Store, substitua a assinatura de debug usada no build release por uma chave de produção (upload key).

## Gerar APK sem instalar Flutter localmente
O projeto inclui `.github/workflows/build-android.yml`. Coloque a pasta em um repositório GitHub, abra **Actions > Build Android APK > Run workflow** e baixe o artefato **SaldoCerto-Android** ao final.

## Observação
Este pacote contém a estrutura Android completa e está pronto para compilação. O APK não foi compilado neste ambiente porque o Flutter/Android SDK não está instalado aqui.
