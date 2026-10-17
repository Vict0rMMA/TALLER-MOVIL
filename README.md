# Vestidos de baño

Taller Integrador 2 + 3 · Desarrollo Móvil

## Integrantes

- Víctor Manuel Monsalve Aguilar
- Ximena Ruiz Arias

## Descripción

Aplicación Flutter que consulta un catálogo de vestidos de baño desde un JSON remoto y permite guardar una prioridad y una nota personal por producto.
Las notas se guardan primero en Drift (SQLite) y después se sincronizan con Cloud Firestore.

## Requisitos

- Flutter 3.44 o superior (Dart 3.11.5 o superior)
- Android Emulator (la configuración de Firebase es solo para Android)
- Firebase CLI y FlutterFire CLI para generar `lib/firebase_options.dart`

## Cómo ejecutar

1. Instalar dependencias:

   ```
   flutter pub get
   ```

2. Generar el código de Drift (solo si se cambia la tabla; `app_database.g.dart` ya viene incluido):

   ```
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Configurar Firebase (crea `lib/firebase_options.dart`):

   ```
   firebase login
   dart pub global activate flutterfire_cli
   dart pub global run flutterfire_cli:flutterfire configure --project=<PROJECT_ID> --platforms=android
   ```

   En Firebase Console se debe crear la base de Firestore en modo de prueba. La colección `product_notes` se crea sola con la primera nota.

4. Ejecutar en el emulador:

   ```
   flutter run
   ```

## Estructura

```
data/
  products.json                         catálogo que consume la app
lib/
  main.dart                             inicializa Firebase y crea las dependencias
  product_screen.dart                   catálogo + botón Sincronizar pendientes
  product_detail_page.dart              detalle, prioridad, nota y estado de sincronización
  product_card.dart                     tarjeta de cada producto
  models/
    product.dart
    product_note.dart
  services/
    product_service.dart                petición HTTP y manejo de errores
  local/
    product_notes_table.dart            tabla de Drift
    app_database.dart                   base products.sqlite
    app_database.g.dart                 generado por build_runner
    product_note_local_data_source.dart
  remote/
    product_note_remote_data_source.dart  escritura en Firestore
  repositories/
    product_note_repository.dart        coordina Drift y Firestore
```

## Preguntas

1. ¿Para qué sirve pendingSync?

   Es una marca que guardamos en Drift junto a cada nota para saber si ese cambio ya llegó a Firestore. Cuando guardamos una nota queda en `true` (pendiente) y solo cambia a `false` cuando Firestore confirma que la recibió. El botón "Sincronizar pendientes" usa esa marca para enviar únicamente las notas que faltan, y en el detalle la usamos para mostrar "Pendiente" o "Sincronizado".

2. ¿Por qué se guarda primero en Drift?

   Para que la nota nunca se pierda, aunque no haya internet o Firebase falle. Drift guarda en el celular y no depende de la red, entonces el usuario siempre puede guardar. Después se intenta enviar a Firestore. Si lo hiciéramos al revés y Firebase fallara, la nota se perdería.

3. ¿Qué función cumple el Repository?

   Es la capa intermedia entre las pantallas y los datos. La pantalla solo le pide guardar una nota, leer la nota de un producto o sincronizar los pendientes, y el Repository decide cómo hacerlo: primero guarda en Drift, después intenta Firestore y, si sale bien, marca la nota como sincronizada. Así las pantallas no conocen Drift ni Firebase, y si cambia la forma de guardar no hay que tocar la interfaz.

4. ¿Qué ocurre si Firebase falla?

   La nota no se pierde porque ya quedó guardada en Drift. El error se captura en el Repository, la app no se cae y la nota queda con `pendingSync = true`, por eso en el detalle aparece "Pendiente". Cuando vuelve la conexión se toca "Sincronizar pendientes" y la nota se envía. Como el documento en Firestore usa el `productId` como id, reenviarla no crea duplicados: se actualiza el mismo documento.
