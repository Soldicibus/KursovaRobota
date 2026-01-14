# ORM Адаптация для Features

## Обзор

Создана полная адаптация ORM (Object-Relational Mapping) под сервис features с использованием паттерна MVC (Model-View-Controller). Все сервисы, контролеры и маршруты подключены к основному роутеру.

## Структура проекта

### Директории

```
features/
├── roles/              # Управление ролями
│   ├── RoleService.js
│   ├── RoleController.js
│   └── RoleRouter.js
├── userroles/          # Управление ролями пользователей
│   ├── UserRoleService.js
│   ├── UserRoleController.js
│   └── UserRoleRouter.js
├── users/              # Управление пользователями
│   ├── UserService.js
│   ├── UserController.js
│   └── UserRouter.js
├── teachers/           # Управление учителями
│   ├── TeacherService.js
│   ├── TeacherController.js
│   └── TeacherRoutes.js
├── students/           # Управление студентами (существующий)
├── temp/               # Временные данные (существующий)
├── auth/               # Аутентификация (существующий)
└── router.js           # Главный маршрутизатор
```

## Компоненты

### 1. **Roles API** (`/api/roles`)

#### Endpoints:
- `GET /api/roles/` - Получить все роли
- `GET /api/roles/:id` - Получить роль по ID
- `POST /api/roles/` - Создать новую роль
  - Body: `{ "roleName": "admin" }`
- `PATCH /api/roles/:id` - Обновить роль
  - Body: `{ "roleName": "newadmin" }`
- `DELETE /api/roles/:id` - Удалить роль

#### Layers:
- **RoleService**: Бизнес-логика операций с ролями
- **RoleController**: Обработка HTTP запросов
- **RoleRouter**: Определение маршрутов
- **RoleModel** (в `/lib/models/RoleModel.js`): Работа с БД

---

### 2. **User Roles API** (`/api/userroles`)

#### Endpoints:
- `GET /api/userroles/:userId` - Получить все роли пользователя
- `POST /api/userroles/assign` - Назначить роль пользователю
  - Body: `{ "userId": 1, "roleId": 2 }`
- `DELETE /api/userroles/remove` - Удалить роль у пользователя
  - Body: `{ "userId": 1, "roleId": 2 }`

#### Layers:
- **UserRoleService**: Управление ролями пользователей
- **UserRoleController**: Обработка HTTP запросов
- **UserRoleRouter**: Определение маршрутов
- **UserRoleModel** (в `/lib/models/UserRoleModel.js`): Работа с БД

---

### 3. **Users API** (`/api/users`)

#### Endpoints:
- `GET /api/users/` - Получить всех пользователей
- `GET /api/users/:id` - Получить пользователя по ID
- `POST /api/users/` - Создать нового пользователя
  - Body: `{ "username": "john", "email": "john@example.com", "password": "pass123" }`
- `PATCH /api/users/:id` - Обновить пользователя
  - Body: `{ "username": "john", "email": "john@example.com", "password": "pass123" }`
- `DELETE /api/users/:id` - Удалить пользователя
- `POST /api/users/reset-password` - Сбросить пароль
  - Body: `{ "userId": 1, "newPassword": "newpass123" }`

#### Layers:
- **UserService**: Бизнес-логика пользователей
- **UserController**: Обработка HTTP запросов
- **UserRouter**: Определение маршрутов
- **UserModel** (в `/lib/models/UserModel.js`): Работа с БД

---

### 4. **Teachers API** (`/api/teachers`)

#### Endpoints:
- `GET /api/teachers/` - Получить всех учителей
- `GET /api/teachers/:id` - Получить учителя по ID
- `GET /api/teachers/with-classes` - Получить учителей с их классами
- `GET /api/teachers/salary?teacherId=1&fromDate=2024-01-01&toDate=2024-12-31` - Получить зарплату учителя
- `POST /api/teachers/` - Создать нового учителя
  - Body: `{ "name": "John", "surname": "Doe", "patronym": "Smith", "phone": "+1234567890" }`
- `PATCH /api/teachers/:id` - Обновить учителя
  - Body: `{ "name": "John", "surname": "Doe", "patronym": "Smith", "phone": "+1234567890" }`
- `DELETE /api/teachers/:id` - Удалить учителя

#### Layers:
- **TeacherService**: Бизнес-логика учителей
- **TeacherController**: Обработка HTTP запросов
- **TeacherRoutes**: Определение маршрутов (существующий файл)
- **TeacherModel** (в `/lib/models/TeacherModel.js`): Работа с БД

---

## Архитектура

### MVC Pattern

```
Request → Router → Controller → Service → Model → Database
Response ← Router ← Controller ← Service ← Model ← Database
```

### Слои:

1. **Router** (`*Router.js`, `*Routes.js`)
   - Определяет HTTP маршруты
   - Связывает endpoints с методами контролера

2. **Controller** (`*Controller.js`)
   - Обрабатывает HTTP запросы и ответы
   - Валидирует входные данные
   - Вызывает методы сервиса

3. **Service** (`*Service.js`)
   - Содержит бизнес-логику
   - Обрабатывает ошибки
   - Вызывает методы модели

4. **Model** (`*Model.js` в `/lib/models/`)
   - Работает непосредственно с базой данных
   - Выполняет SQL запросы и процедуры
   - Обрабатывает ошибки БД

---

## Подключение к главному роутеру

В файле `features/router.js` все маршруты подключены:

```javascript
import { Router } from "express";
import tempRouter from "./temp/tempRouter.js";
import studentsRouter from "./students/StudentRouter.js";
import teacherRouter from "./teachers/TeacherRoutes.js";
import userRoleRouter from "./userroles/UserRoleRouter.js";
import userRouter from "./users/UserRouter.js";
import roleRouter from "./roles/RoleRouter.js";

const router = Router();

router.use("/temp", tempRouter);
router.use("/students", studentsRouter);
router.use("/teacher", teacherRouter);
router.use("/userroles", userRoleRouter);
router.use("/users", userRouter);
router.use("/roles", roleRouter);

export default router;
```

В главном файле `index.js` главный роутер подключен:

```javascript
app.use("/api", mainRouter);
```

---

## Типичный Flow запроса

### Пример: GET /api/users/1

1. **Router** перехватывает запрос и вызывает `UserController.getUserById()`
2. **Controller** извлекает параметр `:id`, валидирует его и вызывает `UserService.getUserById(id)`
3. **Service** обрабатывает логику и вызывает `UserModel.findById(id)`
4. **Model** выполняет SQL запрос к БД
5. **Model** возвращает результат в **Service**
6. **Service** возвращает результат в **Controller**
7. **Controller** отправляет JSON ответ клиенту

---

## Обработка ошибок

Все слои имеют try-catch блоки для обработки ошибок:

- **Model**: Обрабатывает ошибки БД (foreign keys, duplicates и т.д.)
- **Service**: Обрабатывает бизнес-логику ошибки
- **Controller**: Отправляет HTTP ответы с кодами ошибок

---

## Используемые модели БД

- `RoleModel` - Таблица `roles`
- `UserModel` - Таблица `users`
- `UserRoleModel` - Таблица `userrole`
- `TeacherModel` - Таблица `teacher`

---

## Примеры использования

### Создать нового пользователя

```bash
curl -X POST http://localhost:3000/api/users/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "securepass123"
  }'
```

### Назначить роль пользователю

```bash
curl -X POST http://localhost:3000/api/userroles/assign \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "roleId": 2
  }'
```

### Получить все роли пользователя

```bash
curl -X GET http://localhost:3000/api/userroles/1
```

### Получить всех учителей с их классами

```bash
curl -X GET http://localhost:3000/api/teachers/with-classes
```

---

## Файлы созданные/измененные

### Новые файлы:

```
features/
├── roles/
│   ├── RoleService.js ✅
│   ├── RoleController.js ✅
│   └── RoleRouter.js ✅
├── userroles/
│   ├── UserRoleService.js ✅
│   ├── UserRoleController.js ✅
│   └── UserRoleRouter.js ✅
├── users/
│   ├── UserService.js ✅
│   ├── UserController.js ✅
│   └── UserRouter.js ✅
└── teachers/
    ├── TeacherService.js ✅
    └── TeacherController.js ✅
```

### Измененные файлы:

```
features/
└── router.js ✅ (добавлены все новые маршруты)
```

---

## Итоговая структура API

```
BASE_URL: http://localhost:3000/api

Roles:
  GET    /roles
  GET    /roles/:id
  POST   /roles
  PATCH  /roles/:id
  DELETE /roles/:id

Users:
  GET    /users
  GET    /users/:id
  POST   /users
  PATCH  /users/:id
  DELETE /users/:id
  POST   /users/reset-password

User Roles:
  GET    /userroles/:userId
  POST   /userroles/assign
  DELETE /userroles/remove

Teachers:
  GET    /teachers
  GET    /teachers/:id
  GET    /teachers/with-classes
  GET    /teachers/salary
  POST   /teachers
  PATCH  /teachers/:id
  DELETE /teachers/:id
```

---

## Заключение

Адаптация ORM полностью завершена. Все сервисы, контролеры и маршруты следуют унифицированной архитектуре MVC, что обеспечивает:

✅ **Масштабируемость** - Легко добавить новые модули
✅ **Тестируемость** - Слои разделены и легко тестируются
✅ **Переиспользуемость** - Сервисы и модели могут быть использованы в разных местах
✅ **Поддерживаемость** - Четкая структура облегчает понимание кода
✅ **Обработка ошибок** - Единообразная обработка ошибок на всех уровнях

