<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/brand/offmoney-logo-dark.png">
    <img src="assets/brand/offmoney-logo.png" width="320" alt="OffMoney">
  </picture>
</h1>

<p align="center">
  Controle financeiro mensal pessoal para Android: entrada, gastos fixos, parcelados e variáveis, fechamento de mês e um saldo que pode ser auditado linha a linha. Offline e sem IA.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.6-02569B?logo=flutter" alt="Flutter 3.41.6"/>
  <img src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart" alt="Dart 3.11"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Plataforma: Android"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="Licença: MIT"/>
  <img src="https://img.shields.io/badge/status-early%20development-orange" alt="Status: em desenvolvimento inicial"/>
  <img src="https://img.shields.io/badge/domain%20coverage-100%25-brightgreen" alt="Cobertura do domínio: 100% das linhas"/>
  <img src="https://img.shields.io/badge/network-none-lightgrey" alt="Sem acesso à rede"/>
</p>

<p align="center">
  <a href="README.md">Read in English</a>
</p>

---

> [!NOTE]
> O OffMoney é uma ferramenta de controle pessoal, não consultoria financeira. Confira seus valores e decisões; o software não tem garantia (veja a [licença](LICENSE)).

## Sumário

- [Por que o OffMoney](#por-que-o-offmoney)
- [Funcionalidades](#funcionalidades)
- [Como funciona](#como-funciona)
- [Primeiros passos](#primeiros-passos)
- [Build de release](#build-de-release)
- [Releases](#releases)
- [Dados e backup](#dados-e-backup)
- [Arquitetura](#arquitetura)
- [Testes e qualidade](#testes-e-qualidade)
- [Status do projeto](#status-do-projeto)
- [Privacidade](#privacidade)
- [Licença](#licença)

## Por que o OffMoney

O OffMoney é um orçamento mensal que fica fora da rede. Não tem conta, nem conexão com banco, nem nuvem, nem IA: você digita o que entra e o que sai, e o app faz as contas sempre do mesmo jeito.

- **Exato.** Valores em centavos inteiros, cada regra com uma única implementação testada, e todo total recalculado a partir dos itens.
- **Auditável.** O saldo sempre mostra a conta inteira, e toda alteração fica registrada com o valor antigo e o novo.
- **Privado.** Os builds de release não têm permissão de internet; seus dados só saem do celular quando você exporta um backup.

## Funcionalidades

- **Quatro categorias fixas.** Entrada Mensal, Gastos Fixos, Gastos Parcelados e Gastos Variáveis, sempre nessa ordem, cada uma com seu subtotal.
- **Linha de auditoria.** O saldo aparece sempre como `(Entrada) - (Fixos + Parcelados + Variáveis) = Saldo`, com os valores, fixo no rodapé da tela.
- **Fechamento com prévia.** Antes de fechar, o app mostra cada efeito: gastos variáveis zerados, parcelas que avançam ou terminam, gastos fixos mantidos, o saldo final e a entrada do mês seguinte.
- **Digitação cuidadosa.** Campo de moeda preenchido da direita, com estado vazio diferente de R$ 0,00; confirmação quando um gasto passa do saldo restante, quando parece duplicado e antes de excluir.
- **Histórico.** Meses fechados ficam somente leitura, com a própria linha de auditoria.
- **Compartilhar.** Um resumo em texto de qualquer mês pela folha de compartilhamento do Android.
- **Backup.** Exportação em JSON versionado com todos os meses, gastos e alterações, e importação que valida o arquivo inteiro antes de substituir qualquer coisa.
- **Histórico de alterações.** Toda escrita registra os valores antigo e novo na mesma transação.
- **Tema.** Claro, escuro ou seguindo o sistema, escolhido pelo menu.

## Como funciona

Cada mês tem uma referência (por exemplo `nov/2026`) e existe sempre exatamente um mês aberto.

| Categoria | Durante o mês | No fechamento |
|---|---|---|
| Entrada Mensal | Um valor, editável | Mantida no mês seguinte, a menos que outra seja digitada |
| Gastos Fixos | Incluídos, editados e excluídos livremente | Copiados para o mês seguinte |
| Gastos Parcelados | Mostrados como `atual/total`; a última parcela leva a marca "Final" | Avançam uma parcela; as compras que terminam saem |
| Gastos Variáveis | Com data, nunca no futuro | Zerados |

O fechamento aplica tudo numa única transação do banco e não pode ser desfeito. Uma segunda confirmação do mesmo fechamento não grava nada.

A linha de auditoria de um mês com entrada de R$ 4.800,00:

```text
4.800,00 - (2.504,00 + 790,50 + 0,00) = 1.505,50
```

## Primeiros passos

Requisitos: Flutter 3.41.6 (Dart 3.11), Android SDK e Java 17.

O código gerado (Drift e traduções) não é versionado. Depois de clonar, e sempre que tabelas ou textos da interface mudarem:

```bash
flutter pub get
dart run build_runner build
flutter gen-l10n
```

Depois rode o app num celular ou emulador:

```bash
flutter run
```

Builds de debug instalam um app separado, `com.azevedo1z.gemify.debug` ("OffMoney Dev"), então o desenvolvimento nunca toca nos dados do app de uso diário.

## Build de release

O release é assinado com um keystore guardado fora do repositório. Crie `android/key.properties` (ignorado pelo Git):

```properties
storeFile=C:/caminho/para/offmoney-release.jks
storePassword=...
keyAlias=offmoney
keyPassword=...
```

Sem esse arquivo o build de release para com erro, para nunca gerar um APK assinado com outra chave.

```bash
flutter build apk --release        # instalação direta
flutter build appbundle --release  # Google Play
flutter install --release
```

No Google Play, o app usa o Play App Signing: o Google assina o que os usuários baixam, e este keystore é a chave de upload. Uma chave de upload perdida pode ser redefinida pelo suporte do Play Console.

> [!WARNING]
> Guarde uma cópia do keystore e do `key.properties`. APKs instalados fora do Play são assinados diretamente com esta chave: sem ela não é possível atualizá-los, e reinstalar apaga os dados do app. Exporte um backup pelo app antes de qualquer reinstalação.

## Releases

As versões seguem o [Versionamento Semântico](https://semver.org/lang/pt-BR/) e ficam apenas nas [GitHub Releases](https://github.com/azevedo1z/Gemify/releases); não há arquivo de changelog. Os commits seguem os [Conventional Commits](https://www.conventionalcommits.org/pt-br/v1.0.0/), e as notas da release são montadas a partir deles. Enviar uma tag `vX.Y.Z` dispara o [workflow de release](.github/workflows/release.yml), que confere se a tag bate com o `version` do `pubspec.yaml` e cria a GitHub Release com as notas agrupadas a partir dos commits desde a tag anterior (funcionalidades, correções, outras mudanças). Cada release traz só o código-fonte; os builds assinados são feitos localmente (veja [Build de release](#build-de-release)).

Para publicar uma release:

1. Ajuste `version: X.Y.Z+N` no `pubspec.yaml`. `X.Y.Z` é o nome da versão e precisa bater com a tag; `N` é o número de build (o `versionCode` do Android), que precisa ser maior que o anterior a cada envio ao Google Play.
2. Faça o commit `chore(release): vX.Y.Z` e envie para a `master`.
3. Rode `git tag vX.Y.Z` e `git push origin vX.Y.Z`.

As notas podem ser editadas depois na página da release.

## Dados e backup

- Os dados ficam num banco SQLite local (Drift). CHECKs, chaves estrangeiras e um único mês aberto repetem as regras do domínio como segunda linha de defesa.
- O backup automático e a transferência entre aparelhos do Android estão desligados, então a exportação em JSON é o único backup. O arquivo exportado não é criptografado: guarde-o em local seguro.
- A importação valida o arquivo inteiro (formato, versão, valores inteiros, meses em ordem, cada gasto) e substitui todos os dados numa única transação. Um arquivo inválido não altera nada.
- O esquema é versionado em `drift_schemas/`. Ao mudar tabelas, aumente `schemaVersion`, escreva a migração e rode `dart run drift_dev make-migrations`.

## Arquitetura

```text
lib/
├── domain/        Regras em Dart puro: dinheiro, meses, gastos, validações, avisos e o plano de fechamento
├── application/   Casos de uso, a porta do repositório, o relógio e o codec do backup
├── data/          Banco Drift e a implementação do repositório
└── presentation/  Providers do Riverpod, telas, widgets compartilhados, tema e textos em pt-BR
```

As dependências apontam para dentro: o domínio não importa nada de Flutter, Drift ou `intl` e nunca lê o relógio. Dinheiro é um número inteiro de centavos em todo lugar, e todo total é calculado a partir dos itens a cada leitura.

## Testes e qualidade

```bash
flutter analyze
flutter test --coverage
dart run tool/check_domain_coverage.dart
flutter test integration_test
```

- Testes unitários do domínio, com 100% de cobertura de linhas exigida no CI.
- Testes de dados num banco em memória: constraints, transações, rollbacks e a proteção do fechamento.
- Testes de aceitação que rodam um ciclo mensal completo, de um fechamento ao seguinte, e conferem cada total até o centavo.
- Testes de widget de todas as telas e fluxos, inclusive os caminhos de falha.
- O teste de integração precisa de um celular ou emulador conectado.
- `very_good_analysis` sem nenhum aviso, e nenhum comentário no código escrito à mão.

O [CI](.github/workflows/ci.yml) roda o analisador, os testes e a checagem de cobertura a cada push na `master` e em pull requests. Um dos testes confere que o "hoje" é a data local e só roda num fuso atrás de UTC, por isso o CI usa `TZ=America/Sao_Paulo`.

## Status do projeto

Desenvolvimento inicial (`0.x`), a caminho do Google Play. O esquema do banco e o formato do backup ainda podem mudar entre versões menores, sempre com migração ou um caminho de importação documentado.

## Privacidade

O OffMoney não tem conta, nem analytics, nem acesso à rede nos builds de release. Veja a [política de privacidade](PRIVACY_POLICY.md) (em inglês). Para relatar um problema de segurança, veja a [política de segurança](SECURITY.md) (em inglês).

## Licença

[MIT](LICENSE)
