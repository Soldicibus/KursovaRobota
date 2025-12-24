# API Тестирование - Краткое руководство

## Доступные endpoints

### 1. Роли (Roles)

```bash
# Получить все роли
GET /api/roles

# Получить роль по ID
GET /api/roles/1

# Создать роль
POST /api/roles
Body: { "roleName": "admin" }

# Обновить роль
PATCH /api/roles/1
Body: { "roleName": "superadmin" }

# Удалить роль
DELETE /api/roles/1
```

### 2. Пользователи (Users)

```bash
# Получить всех пользователей
GET /api/users

# Получить пользователя по ID
GET /api/users/1

# Создать пользователя
POST /api/users
Body: {
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securepass123"
}

# Обновить пользователя
PATCH /api/users/1
Body: {
  "username": "jane_doe",
  "email": "jane@example.com",
  "password": "newpass123"
}

# Удалить пользователя
DELETE /api/users/1

# Сбросить пароль
POST /api/users/reset-password
Body: {
  "userId": 1,
  "newPassword": "resetpass123"
}
```

### 3. Роли пользователей (User Roles)

```bash
# Получить все роли пользователя
GET /api/userroles/1

# Назначить роль пользователю
POST /api/userroles/assign
Body: {
  "userId": 1,
  "roleId": 2
}

# Удалить роль у пользователя
DELETE /api/userroles/remove
Body: {
  "userId": 1,
  "roleId": 2
}
```

### 4. Учителя (Teachers)

```bash
# Получить всех учителей
GET /api/teachers

# Получить учителя по ID
GET /api/teachers/1

# Получить учителей с их классами
GET /api/teachers/with-classes

# Получить зарплату учителя
GET /api/teachers/salary?teacherId=1&fromDate=2024-01-01&toDate=2024-12-31

# Создать учителя
POST /api/teachers
Body: {
  "name": "John",
  "surname": "Doe",
  "patronym": "Smith",
  "phone": "+1234567890"
}

# Обновить учителя
PATCH /api/teachers/1
Body: {
  "name": "Jane",
  "surname": "Smith",
  "patronym": "Johnson",
  "phone": "+0987654321"
}

# Удалить учителя
DELETE /api/teachers/1
```

## Инструменты для тестирования

### Вариант 1: cURL (команднаястрока)

```bash
# Пример GET запроса
curl http://localhost:3000/api/users

# Пример POST запроса
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"pass123"}'
```

### Вариант 2: Postman

1. Создать коллекцию "TermPaper API"
2. Создать папки для каждого ресурса (Roles, Users, UserRoles, Teachers)
3. Добавить requests для каждого endpoint
4. Сохранить и поделиться коллекцией

### Вариант 3: VS Code REST Client расширение

```rest
# File: test.http

### Get all users
GET http://localhost:3000/api/users

### Create user
POST http://localhost:3000/api/users
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securepass123"
}

### Get user by ID
GET http://localhost:3000/api/users/1

### Create role
POST http://localhost:3000/api/roles
Content-Type: application/json

{
  "roleName": "admin"
}

### Assign role to user
POST http://localhost:3000/api/userroles/assign
Content-Type: application/json

{
  "userId": 1,
  "roleId": 2
}
```

## Коды ответов

- `200 OK` - Успешный GET/PATCH запрос
- `201 Created` - Успешное создание (POST)
- `400 Bad Request` - Ошибка валидации или ошибка БД
- `404 Not Found` - Ресурс не найден
- `500 Internal Server Error` - Ошибка сервера

## Типичные ошибки

1. **400 - userId and roleId are required**
   - Убедитесь, что отправляете оба параметра в body

2. **400 - User ID is required**
   - Убедитесь, что указан ID в URL параметре

3. **400 - Invalid User ID or Role ID provided**
   - Проверьте, что пользователь и роль существуют в БД

4. **400 - Cannot delete role because it is assigned to users**
   - Сначала удалите все связи пользователей с этой ролью

---

**Примечание:** Убедитесь, что сервер запущен на порту 3000 перед тестированием.

