# KipuBank - Smart Contract

## Descripción

**KipuBank** es un contrato inteligente en Solidity que permite a los usuarios:

- Depositar tokens nativos (ETH) en una bóveda personal.
- Retirar fondos de su bóveda con un límite máximo por transacción.
- Respetar un límite global de depósitos (`bankCap`) establecido al momento del despliegue.
- Llevar un registro de depósitos y retiros exitosos.
- Validar condiciones de seguridad usando **errores personalizados**, modifiers y el patrón **checks-effects-interactions**.
- Emitir eventos para cada depósito y retiro exitoso, así como para cada actualización de saldo.

### Funcionalidades principales

- `depositToAccount()` → Deposita ETH en la cuenta del usuario, validando el `bankCap`.
- `extractFromAccount(uint256 _quantity)` → Retira ETH hasta un límite máximo (`i_maxExtract`) y verifica que haya saldo suficiente.
- `getBalance()` → Consulta el saldo actual de la cuenta del usuario.
- `_updateAccountBalance(uint256 _quantity, Operation _operation)` → Función privada que actualiza el balance de la cuenta y emite un evento.
- Modifiers:
  - `underBankCap(uint256 _value)` → Verifica que no se exceda el límite global de depósitos.
  - `validExtract(uint256 _quantity)` → Verifica que la cantidad a retirar no exceda el límite por transacción ni el saldo disponible.

---

## Despliegue

1. Abrir [Remix IDE](https://remix.ethereum.org/).
2. Crear un archivo `KipuBank.sol` y pegar el código del contrato.
3. Seleccionar la versión de compilador **0.8.30**.
4. Compilar el contrato.
5. Ir a la pestaña **Deploy & Run Transactions**.
6. Configurar los parámetros del constructor:
   - `_maxExtract`: límite máximo por retiro (en wei).
   - `_bankCap`: límite total de depósitos del contrato (en wei).
7. Hacer clic en **Deploy**.

---

## Interacción con el contrato

### Depositar ETH

1. Seleccionar la función `depositToAccount`.
2. Ingresar la cantidad de ETH en el campo **Value**.
3. Hacer clic en **transact**.
4. Si el depósito es exitoso:
   - Se actualizará el balance de tu cuenta.
   - Se emitirá el evento `KipuBank_SuccessfulDeposit`.

### Retirar ETH

1. Seleccionar la función `extractFromAccount`.
2. Ingresar la cantidad a retirar (`_quantity`) en wei.
3. Hacer clic en **transact**.
4. Si la extracción es exitosa:
   - Se enviará ETH a tu dirección.
   - Se actualizará el balance de tu cuenta.
   - Se emitirá el evento `KipuBank_SuccessfulExtract`.

### Consultar saldo

- Llamar a `getBalance()` para ver el saldo actual de tu cuenta.

---

### Eventos disponibles

- `KipuBank_SuccessfulDeposit(address wallet, uint256 quantity)`
- `KipuBank_SuccessfulExtract(address wallet, uint256 quantity)`
- `KipuBank_SuccessfulBalanceUpdate(address wallet, uint256 quantity)`

---

### Errores personalizados

- `KipuBank_FailedDeposit(address wallet, uint256 quantity, string reason)`
- `KipuBank_FailedExtract(address wallet, uint256 quantity, string reason)`

Estos errores se lanzan si se violan las condiciones del contrato, como superar el límite global de depósitos o intentar extraer más de lo permitido.

---

### Notas de seguridad

- El contrato previene depósitos directos usando la función `receive()`.
- Se sigue el patrón **checks-effects-interactions** para minimizar riesgos.
- Las transferencias de ETH se realizan usando `call{value: ...}` para mayor seguridad.
