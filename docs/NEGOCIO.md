# New Terra — Reglas de negocio

Qué hace el sistema y con qué reglas, en términos de negocio. Para lo técnico ver
`src/frontend/CLAUDE.md` y `src/backend/CLAUDE.md`. Cada regla indica dónde vive
en el código, para poder verificarla.

## Glosario

| Término | Significado |
|---|---|
| Cliente | Comprador. Tiene asignada una sublista de precios para la lista A y otra para la V (`LISTA A` / `LISTA V`). |
| Lista A / Lista V | Las dos listas de precios. Un presupuesto suma productos de ambas y lleva subtotal y descuento por separado para cada una. |
| Presupuesto | Pedido de un cliente. Al facturarse genera la deuda en la cuenta corriente y descuenta stock. |
| Cuenta corriente | Movimientos de dinero de un cliente (o de un proveedor) con el saldo acumulado. |
| NC / ND | Nota de crédito (a favor del cliente) / Nota de débito (en contra del cliente). |
| Portal | Sitio donde el cliente ve el catálogo y hace pedidos por su cuenta (`/portal/*`). |
| Baja | Borrado lógico. Clientes y presupuestos se marcan con `FECHA_BAJA` / `fecha_baja`; no se borran. |

## Cuenta corriente de clientes

Tipos de movimiento (`src/backend/src/utils/enums.js`):

| Aumentan la deuda | Disminuyen la deuda |
|---|---|
| Facturado, Deuda, Nota de débito | Pago, Nota de crédito |

**Saldo** = (Pagos + NC) − (Facturado + Deuda + ND)
(`src/backend/src/calculates/accountsCalculates.js`).
- Los montos de deuda se toman en valor absoluto: da igual si están guardados en positivo o en negativo.
- Un saldo negativo significa que el cliente debe.
- Cada movimiento guarda también `totalBalance`, que es el saldo acumulado después de ese movimiento.

Carga manual desde el frontend (`ClientBalanceForm.tsx`):
- El monto se carga siempre en positivo; el tipo define si suma o resta.
- Solo Pago y Facturado piden forma de pago. Las formas de pago son: Efectivo, Cajas, Cheque, Transferencia - Depósito, Retención Ganancias, Retención IB CABA y Retención IB BS AS.
- Una transferencia pide elegir el proveedor al que se hizo.
- La vista muestra por defecto los últimos 60 días.

## Presupuestos

- **Total** = subtotal A + subtotal V − descuento.
- **Estados** (`status`):
  - **Generado**: recién creado, desde el sistema o desde el portal. Se puede editar.
  - **Facturado**: el frontend lo deja en solo lectura.
- **Entrega**: se registra aparte del estado, con el flag `enviado`. Pasa a `true` cuando el presupuesto se asigna a una distribución, y vuelve a `false` si se la quita.

Al **facturar** (`budgets.service.js`), todo en una misma transacción:
1. Se guarda `facturadoBy` / `facturadoAt` y una entrada en `auditLog`.
2. Se descuenta stock por cada producto (ver Stock).
3. Se crea el movimiento "Facturado" en la cuenta corriente por el total (en negativo).

Si el presupuesto vino del portal (`channel: "portal"`), al facturarlo el frontend ofrece avisarle al cliente por email. El aviso requiere que el cliente tenga `PORTAL_EMAIL` cargado.

Al **dar de baja** un presupuesto se marca `fecha_baja` y se borra el evento "creado" del historial del cliente.

## Notas de crédito y débito

- Al crear una NC o una ND se genera automáticamente el movimiento en la cuenta corriente, con el saldo actualizado (`creditNotes.services.js`, `debitNotes.services.js`).
- Al borrarlas, en cambio, se hace un borrado físico de la nota y **no se revierte** el movimiento en la cuenta corriente.

## Proveedores

- **Tipos de movimiento**:
  - Aumentan la deuda con el proveedor: Compra, Declarado, No declarado y Nota de débito.
  - La disminuyen: Pago y Nota de crédito.
  - El saldo se calcula igual que en clientes.
- **Formas de pago**: Cheque, Efectivo y Transferencia.
- **Comprobantes**: Declarado o No declarado.
- **Compras** (`purchases.service.js`): cuando una compra pasa a estado `entregada`, se hacen tres cosas:
  - Se suma stock (movimiento "Ingreso").
  - Se registra una "Compra" en la cuenta corriente del proveedor.
  - Si se marcó "pagado en el momento", se registra también el "Pago".

## Stock

- Movimientos: **Ingreso** (compra o carga manual) y **Venta** (egreso).
- **Costo promedio**: promedio ponderado (cantidad × costo unitario) de los Ingresos de los últimos 60 días (`stock.service.js`).
- **Venta al facturar**:
  - Se descuenta como máximo lo disponible: el stock nunca queda negativo.
  - Si un producto no tiene stock cargado, se saltea y el presupuesto se factura igual (ver `src/backend/docs/TROUBLESHOOTING.md`).
- **Venta interna a empleados**: descuenta stock y arranca en estado "Pendiente".

## Portal de clientes

- **Acceso** (`clientAuth.service.js`):
  - Requisitos: el cliente debe tener `PORTAL_ENABLED: true` y un `PORTAL_EMAIL`. Este mail es distinto del email comercial.
  - Login sin contraseña: se envía un código de 6 dígitos por email.
  - El código vence a los 10 minutos, se puede reenviar cada 60 segundos y admite 5 intentos.
  - El código se guarda hasheado.
- **Catálogo**:
  - Muestra solo los productos de las sublistas A y V del cliente, sin incluir los deshabilitados.
  - Si un producto no tiene stock cargado, se puede pedir sin límite. Si tiene, no se puede pedir más de lo disponible.
- **Pedido**:
  - Se crea como presupuesto `Generado`, con `channel: "portal"`.
  - No lleva descuentos y usa los precios de la lista del cliente.
  - Después sigue el circuito normal de presupuestos.
- **Historial**: el cliente ve sus pedidos de los últimos 6 meses.

## Otros módulos

- **Distribución**: asigna presupuestos a un vehículo (patente) o a "Retira". Se refleja en el flag `enviado` del presupuesto.
- **Caja diaria**: se arma a partir de los subtotales A y V de los presupuestos del día.
- **Dashboard**: ventas y principales deudores.
- **Config params**: parámetros generales, incluido el CAE.
- **Catálogo público**: `/new-terra-catalogo.html`, generado mediante una Netlify function.

## Puntos a revisar

Inconsistencias vistas en el código al escribir este documento. No son reglas: son candidatos a bug o a decisión.

- **Estado "Enviado"**: el frontend lo define en `EnumStatusBudget` y lo muestra, pero ningún flujo lo asigna. La entrega se maneja con el flag `enviado`.
- **Facturación duplicada**: el descuento de stock y el movimiento "Facturado" se ejecutan cada vez que se guarda un presupuesto con `status: "Facturado"`, aunque ya estuviera facturado. Hoy lo evita el frontend, porque deja el presupuesto en solo lectura; el backend no lo controla.
- **Borrado de NC/ND**: borrar una nota deja su movimiento en la cuenta corriente, así que el saldo no cambia.
