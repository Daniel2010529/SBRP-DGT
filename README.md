# SBRP · Superweb DGT

Portal de roleplay independiente construido con React, Vite, Express y Supabase. No es una web oficial de la DGT. Se ha añadido CSS responsive en `src/styles.css`.

## Supabase
1. Crea un proyecto en Supabase.
2. En un proyecto nuevo, abre **SQL Editor → New query** y ejecuta `supabase/schema.sql`. Si ya hay tablas/datos, haz copia de seguridad y revisa el SQL antes de ejecutarlo.
3. En **Project Settings → API**, copia la Project URL y la clave pública `anon`/`publishable`. Nunca uses `service_role` ni una clave secreta en el frontend.
4. Tras desplegar, en **Authentication → URL Configuration** configura Site URL y Redirect URLs con la URL de Render.

## GitHub
Crea un repositorio vacío, descomprime el ZIP y abre terminal en la carpeta. Ejecuta (sustituye la URL):
```bash
git init
git add .
git commit -m "Primera versión de SBRP Superweb"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/TU-REPOSITORIO.git
git push -u origin main
```
No subas `.env` ni credenciales.

## Render — Web Service
1. En Render pulsa **New + → Web Service** y conecta el repositorio GitHub.
2. Runtime: **Node**. Build Command: `npm install && npm run build`. Start Command: `npm start`.
3. En **Environment** añade `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` con los valores de Supabase.
4. Despliega. `server.js` sirve la app compilada y sus rutas. El plan gratuito puede suspenderse por inactividad; revisa los límites actuales de Render.

## Primer administrador
Registra primero la cuenta que será administradora. En Supabase SQL Editor ejecuta, sustituyendo el UUID por el ID real:
```sql
update public.profiles set role='admin' where id='UUID-DEL-USUARIO';
```
No asignes admin a usuarios no autorizados.

## Seguridad
La clave del navegador es pública; la protección depende de las políticas RLS de Supabase. Prueba con dos cuentas distintas y revisa las políticas de `supabase/schema.sql`. No introduzcas datos personales reales ni datos oficiales sensibles: es un portal de roleplay.


## Novedades v2 (octubre 2026)

- Centro de incidencias con referencia automática, categoría, asunto, estado y prioridad.
- Avisos y comunicados para el portal; solo personal autorizado puede publicar.
- Exportación CSV de las tablas filtradas para hojas de cálculo.
- Registro interno de auditoría para cambios en vehículos, multas, citas y carnets.
- Protección SQL adicional para impedir que un usuario se conceda el rol `admin` a sí mismo.
- Interfaz adaptada para las nuevas secciones y formularios largos.

### Actualizar Supabase

Si ya tienes una base de datos creada, realiza primero una copia de seguridad. Después revisa y ejecuta el archivo `supabase/schema.sql` desde SQL Editor. Está pensado para crear las tablas nuevas y actualizar las políticas, pero revisa los permisos antes de aplicarlo en un proyecto con datos existentes.

### Funciones incluidas

Cuenta privada, perfil, roles, carnets, vehículos, multas, citas, exámenes, documentos privados, notificaciones, centro de incidencias, comunicados, búsqueda por sección, exportación CSV, panel de administración, controles RLS y auditoría de cambios.

Este portal es para roleplay y no es un servicio oficial de la DGT. No introduzcas datos personales reales ni credenciales de terceros.
