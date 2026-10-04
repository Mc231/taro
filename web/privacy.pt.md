---
title: Política de Privacidade
locale: pt
version: "1.0"
effective: "2026-10-04"
source: en
translation: machine
review: "MACHINE TRANSLATION of privacy.en.md v1.0: native legal review required before publishing (05 §5.3). The English version prevails."
---

# Política de Privacidade do Taro

Versão 1.0 · Em vigor desde 4 de outubro de 2026

## Quem somos

Taro é um app de diário de tarô criado por Volodymyr Shyrochuk, desenvolvedor individual e comerciante nos termos do Regulamento dos Serviços Digitais da UE («nós»). Contato: volodymyr.shyrochuk@gmail.com. Endereço e telefone do comerciante: Rua Skrypnuka, 278, 79049 Lviv, Ucrânia; telefone: +380 93 815 0581.

## Resumo

- Não há conta. O Taro cria um ID de instalação aleatório; nunca pedimos seu nome, e-mail ou número de telefone.
- Seu diário, suas cartas e suas leituras ficam no seu dispositivo. Seu diário é incluído no backup do dispositivo.
- Quando você pede uma leitura com IA, sua pergunta, a tiragem, as cartas tiradas e o idioma do app vão para o nosso servidor, que pede à OpenAI que escreva a interpretação. Sua pergunta não é armazenada no nosso servidor.
- Os anúncios são exibidos pelo Google AdMob, e só depois de você fazer suas escolhas de consentimento.
- Você pode exportar e apagar seus dados no app a qualquer momento.

## Dados que tratamos

- **ID de instalação:** um ID aleatório criado na primeira abertura. Serve para seus créditos de leitura, sua leitura diária gratuita e a prevenção de fraudes.
- **Chave do dispositivo (só Android):** um hash unidirecional do ID do dispositivo Android, usado apenas para evitar abuso das leituras gratuitas. No iOS, o DeviceCheck da Apple guarda um bit com o mesmo fim; nunca vemos um identificador do dispositivo.
- **Fuso horário e idioma do app:** para reiniciar sua leitura diária gratuita à meia-noite local e escrever as leituras no seu idioma.
- **Registros de compra:** o ID da transação da loja, o produto e os créditos concedidos. Nunca recebemos seus dados de pagamento.
- **Metadados de leitura:** tiragem, número de cartas, idioma, versão do prompt, número de tokens, custo, categoria de segurança e resultado. Sem o texto da pergunta.
- **Perguntas para leituras com IA:** enviadas ao provedor de IA para escrever a leitura e não armazenadas no nosso servidor.
- **Textos das leituras:** mantidos criptografados no nosso servidor apenas até o seu dispositivo recebê-los.
- **Denúncias:** se você denunciar uma leitura, guardamos criptografados a pergunta, o texto da leitura e sua nota opcional para podermos analisá-la.
- **Estatísticas:** como o app é usado (por exemplo, quais telas são abertas), via Google Analytics for Firebase, só depois das suas escolhas de consentimento. Nunca enviamos sua pergunta, leitura ou texto do diário para as estatísticas.
- **Dados de falhas:** relatórios de falhas e dados de desempenho, via Firebase Crashlytics.
- **Dados de publicidade:** tratados pelo Google AdMob (veja Publicidade).

## Tratamento por IA

As leituras com IA são escritas pela **OpenAI** (modelos GPT), que atua como nossa operadora. O mesmo provedor verifica a segurança de perguntas e leituras (moderação). O modelo que escreve uma leitura depende da configuração do nosso servidor; se adicionarmos ou trocarmos de provedor, atualizaremos esta política e pediremos sua permissão de novo no app.

- **O que é enviado:** sua pergunta, a tiragem, as cartas tiradas e o idioma do app. Nunca enviamos seu nome, e-mail, ID de instalação ou ID de publicidade.
- **Treinamento:** pelos termos da API da OpenAI, os dados enviados pela API não são usados para treinar seus modelos.
- **Retenção pelo provedor:** a OpenAI pode manter as solicitações à API por até 30 dias para detectar abusos e depois as apaga; as solicitações de moderação não são retidas.
- **Precisão:** as leituras são geradas por IA. Podem ser erradas ou inesperadas e servem apenas para entretenimento e reflexão.

Antes da primeira leitura com IA, o app explica isso e pede sua permissão. Você pode retirá-la a qualquer momento em Ajustes → Leituras com IA; as leituras clássicas continuam funcionando sem IA.

## Publicidade

O Taro mostra anúncios em banner e vídeos com recompensa opcionais do Google AdMob. Antes de qualquer anúncio ser solicitado, o formulário de consentimento do Google (UMP) pede suas escolhas onde a lei exige. No iOS, depois pedimos permissão de rastreamento pela App Tracking Transparency da Apple. Se você recusar, verá anúncios não personalizados. Você pode mudar suas escolhas a qualquer momento em Ajustes → Escolhas de privacidade. O AdMob pode tratar seu ID de publicidade, uma localização aproximada derivada do seu endereço IP e interações com anúncios segundo os termos do Google. A compra de Remover anúncios em banner remove os banners.

## Compras

As compras são processadas pela Apple (App Store) ou pelo Google (Google Play) segundo os termos deles. Recebemos apenas as informações da transação necessárias para conceder suas leituras. Os créditos de leitura estão vinculados a esta instalação: não são restaurados depois que você apaga o app ou seus dados, e o arquivo de exportação não os contém. Remover anúncios em banner pode ser restaurado.

## Bases legais (RGPD/LGPD)

- **Contrato:** as leituras com IA que você solicita, incluindo o envio da sua pergunta ao provedor de IA; compras e créditos de leitura.
- **Consentimento:** anúncios personalizados e, quando exigido, estatísticas.
- **Interesse legítimo:** prevenção de fraudes, incluindo a chave do dispositivo; dados de falhas para manter o app funcionando.

A etapa de permissão de IA no app serve para transparência e para a sua escolha; não é a base legal do tratamento.

## Retenção

- Sua pergunta não é armazenada no nosso servidor.
- O texto da leitura é mantido criptografado até o seu dispositivo confirmar o recebimento, no máximo 7 dias, e depois é apagado.
- As leituras denunciadas são mantidas por 90 dias.
- Os registros contábeis e de compras são mantidos por 7 anos (impostos, reembolsos e prevenção de fraudes) de forma pseudonimizada.
- Os metadados de leitura são mantidos por 13 meses.
- Os registros de anúncios com recompensa são mantidos por 13 meses.
- Os contadores de uso diário são mantidos por 90 dias.
- Os contadores do dispositivo (vinculados à chave do dispositivo no Android) são mantidos por 90 dias.
- Os logs do servidor são mantidos por 7 dias.
- As instalações inativas (24 meses sem atividade e sem créditos restantes) são pseudonimizadas após 24 meses.

## Seus direitos

- **Acesso e portabilidade:** Ajustes → Exportar backup cria um arquivo com seu diário e suas leituras.
- **Eliminação:** Ajustes → Apagar todos os dados apaga os dados do seu dispositivo e pede ao nosso servidor que apague suas leituras, denúncias e histórico de uso. Seus créditos de leitura restantes e Remover anúncios em banner são mantidos, porque são bens comprados.
- **Oposição e retirada do consentimento:** Ajustes → Escolhas de privacidade e Ajustes → Leituras com IA.
- **Reclamação:** você pode reclamar à sua autoridade de proteção de dados.
- **Leis de privacidade de estados dos EUA:** não vendemos suas informações pessoais. Você pode recusar o «compartilhamento» para publicidade direcionada pelo formulário de privacidade exibido nos estados dos EUA.

Para qualquer solicitação, escreva para volodymyr.shyrochuk@gmail.com e inclua o ID de suporte mostrado em Ajustes.

## Crianças

O Taro não é destinado a menores de 16 anos, e não coletamos seus dados de forma consciente.

## Segurança e transferências internacionais

Os dados são criptografados em trânsito (HTTPS). Os textos das leituras e as denúncias são criptografados em repouso. Nosso servidor roda na Cloudflare; nossas operadoras são Cloudflare, OpenAI e Google (Firebase, AdMob). Elas podem tratar dados fora do seu país, inclusive nos Estados Unidos, com base nas Cláusulas Contratuais-Padrão da Comissão Europeia ou em garantia equivalente.

## Alterações

Atualizaremos esta política quando nosso tratamento mudar e mostraremos aqui a nova versão e a data de vigência. Se uma alteração afetar o tratamento por IA, o app pedirá sua permissão de novo.
