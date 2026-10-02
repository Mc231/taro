---
title: Política de privacidad
locale: es
version: "1.0"
effective: "2026-10-02"
source: en
translation: machine
review: "MACHINE TRANSLATION of privacy.en.md v1.0: native legal review required before publishing (05 §5.3). The English version prevails."
---

# Política de privacidad de Taro

Versión 1.0 · En vigor desde el 2 de octubre de 2026

## Quiénes somos

Taro es una app de diario de tarot creada por Volodymyr Shyrochuk, desarrollador individual y comerciante según la Ley de Servicios Digitales de la UE («nosotros»). Contacto: volodymyr.shyrochuk@gmail.com. Dirección y teléfono del comerciante: [OWNER: fill in before publishing, as shown in the App Store and Google Play listings].

## Resumen

- No hay cuenta. Taro crea un ID de instalación aleatorio; nunca pedimos tu nombre, correo electrónico ni número de teléfono.
- Tu diario, tus cartas y tus lecturas se guardan en tu dispositivo. Tu diario se incluye en la copia de seguridad del dispositivo.
- Cuando pides una lectura con IA, tu pregunta, la tirada, las cartas que sacaste y el idioma de la app se envían a nuestro servidor, que pide a OpenAI que escriba la interpretación. Tu pregunta no se guarda en nuestro servidor.
- Los anuncios los muestra Google AdMob, y solo después de que hayas tomado tus decisiones de consentimiento.
- Puedes exportar y eliminar tus datos desde la app en cualquier momento.

## Datos que tratamos

- **ID de instalación:** un ID aleatorio creado en el primer inicio. Sirve para tus créditos de lectura, tu lectura diaria gratuita y la prevención del fraude.
- **Clave del dispositivo (solo Android):** un hash unidireccional del ID del dispositivo Android, usado solo para evitar el abuso de las lecturas gratuitas. En iOS, DeviceCheck de Apple guarda un bit con el mismo fin; nunca vemos un identificador del dispositivo.
- **Zona horaria e idioma de la app:** para reiniciar tu lectura diaria gratuita a tu medianoche local y escribir las lecturas en tu idioma.
- **Registros de compra:** el ID de transacción de la tienda, el producto y los créditos concedidos. Nunca recibimos tus datos de pago.
- **Metadatos de lectura:** tirada, número de cartas, idioma, versión del prompt, número de tokens, coste, categoría de seguridad y resultado. Sin el texto de la pregunta.
- **Preguntas para lecturas con IA:** se envían al proveedor de IA para escribir la lectura y no se guardan en nuestro servidor.
- **Textos de lectura:** se conservan cifrados en nuestro servidor solo hasta que tu dispositivo los recibe.
- **Denuncias:** si denuncias una lectura, guardamos cifrados la pregunta, el texto de la lectura y tu nota opcional para poder revisarla.
- **Analítica:** cómo se usa la app (por ejemplo, qué pantallas se abren), mediante Google Analytics for Firebase, solo después de tus decisiones de consentimiento. Nunca enviamos tu pregunta, tu lectura ni el texto de tu diario a la analítica.
- **Datos de fallos:** informes de fallos y datos de rendimiento, mediante Firebase Crashlytics.
- **Datos publicitarios:** los trata Google AdMob (ver Publicidad).

## Tratamiento por IA

Las lecturas con IA las escribe **OpenAI** (modelos GPT), que actúa como nuestro encargado del tratamiento. El mismo proveedor revisa la seguridad de preguntas y lecturas (moderación). Qué modelo escribe una lectura depende de la configuración de nuestro servidor; si añadimos o cambiamos de proveedor, actualizaremos esta política y volveremos a pedirte permiso en la app.

- **Qué se envía:** tu pregunta, la tirada, las cartas sacadas y el idioma de la app. Nunca enviamos tu nombre, correo, ID de instalación ni ID de publicidad.
- **Entrenamiento:** según las condiciones de la API de OpenAI, los datos enviados a través de la API no se usan para entrenar sus modelos.
- **Conservación por el proveedor:** OpenAI puede conservar las solicitudes a la API hasta 30 días para detectar abusos y después las elimina; las solicitudes de moderación no se conservan.
- **Exactitud:** las lecturas las genera una IA. Pueden ser erróneas o inesperadas y son solo para entretenimiento y reflexión.

Antes de la primera lectura con IA, la app te lo explica y te pide permiso. Puedes retirarlo en cualquier momento en Ajustes → Lecturas con IA; las lecturas clásicas siguen funcionando sin IA.

## Publicidad

Taro muestra anuncios de banner y vídeos de recompensa opcionales de Google AdMob. Antes de solicitar cualquier anuncio, el formulario de consentimiento de Google (UMP) te pide tus decisiones donde la ley lo exige. En iOS, después pedimos permiso de rastreo mediante App Tracking Transparency de Apple. Si lo rechazas, verás anuncios no personalizados. Puedes cambiar tus decisiones en cualquier momento en Ajustes → Opciones de privacidad. AdMob puede tratar tu ID de publicidad, una ubicación aproximada derivada de tu dirección IP y tus interacciones con anuncios según las condiciones de Google. La compra de Quitar los anuncios de banner elimina los banners.

## Compras

Las compras las procesa Apple (App Store) o Google (Google Play) según sus condiciones. Solo recibimos la información de transacción necesaria para concederte tus lecturas. Los créditos de lectura están vinculados a esta instalación: no se restauran tras eliminar la app o sus datos, y el archivo de exportación no los contiene. Quitar los anuncios de banner se puede restaurar.

## Bases jurídicas (RGPD)

- **Contrato:** las lecturas con IA que solicitas, incluido el envío de tu pregunta al proveedor de IA; las compras y los créditos de lectura.
- **Consentimiento:** anuncios personalizados y, cuando sea necesario, analítica.
- **Interés legítimo:** prevención del fraude, incluida la clave del dispositivo; datos de fallos para que la app funcione.

El paso de permiso de IA en la app sirve para la transparencia y tu elección; no es la base jurídica del tratamiento.

## Conservación

- Tu pregunta no se guarda en nuestro servidor.
- El texto de la lectura se conserva cifrado hasta que tu dispositivo confirma la recepción, como máximo 7 días, y después se elimina.
- Las lecturas denunciadas se conservan 90 días.
- Los registros contables y de compras se conservan 7 años (impuestos, reembolsos y prevención del fraude) de forma seudonimizada.
- Los metadatos de lectura se conservan 13 meses.
- Los registros de anuncios con recompensa se conservan 13 meses.
- Los contadores de uso diario se conservan 90 días.
- Los contadores del dispositivo (vinculados a la clave del dispositivo en Android) se conservan 90 días.
- Los registros del servidor se conservan 7 días.
- Las instalaciones inactivas (24 meses sin actividad y sin créditos restantes) se seudonimizan tras 24 meses.

## Tus derechos

- **Acceso y portabilidad:** Ajustes → Exportar copia de seguridad crea un archivo con tu diario y tus lecturas.
- **Supresión:** Ajustes → Eliminar todos los datos borra los datos de tu dispositivo y pide a nuestro servidor que borre tus lecturas, denuncias e historial de uso. Tus créditos de lectura restantes y Quitar los anuncios de banner se conservan, porque son bienes comprados.
- **Oposición y retirada del consentimiento:** Ajustes → Opciones de privacidad y Ajustes → Lecturas con IA.
- **Reclamación:** puedes presentar una reclamación ante tu autoridad de protección de datos.
- **Leyes de privacidad de estados de EE. UU.:** no vendemos tu información personal. Puedes oponerte a que se «comparta» para publicidad dirigida mediante el formulario de privacidad que se muestra en los estados de EE. UU.

Para cualquier solicitud, escribe a volodymyr.shyrochuk@gmail.com e incluye el ID de soporte que aparece en Ajustes.

## Menores

Taro no está dirigida a menores de 16 años y no recopilamos sus datos de forma consciente.

## Seguridad y transferencias internacionales

Los datos se cifran en tránsito (HTTPS). Los textos de lectura y las denuncias se cifran en reposo. Nuestro servidor funciona en Cloudflare; nuestros encargados del tratamiento son Cloudflare, OpenAI y Google (Firebase, AdMob). Pueden tratar datos fuera de tu país, también en Estados Unidos, con las Cláusulas Contractuales Tipo de la Comisión Europea o una garantía equivalente.

## Cambios

Actualizaremos esta política cuando cambie nuestro tratamiento y mostraremos aquí la nueva versión y la fecha de entrada en vigor. Si un cambio afecta al tratamiento por IA, la app volverá a pedirte permiso.
