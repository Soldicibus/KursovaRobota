# Структура проекта ORM Adaptation

## Дерево файлов

```
C:\Repositories\termpaper-db/
├── index.js                           # Главный файл приложения
├── package.json                       # Зависимости проекта
├── ORM_ADAPTATION_GUIDE.md            # 📖 Документация адаптации ORM
├── API_TEST_GUIDE.md                  # 📖 Гайд по тестированию API
├── PROJECT_STRUCTURE.md               # 📖 Этот файл
│
├── lib/                               # Библиотека
│   ├── db.js                          # Подключение к БД (PostgreSQL Pool)
│   └── models/                        # Модели БД
│       ├── ClassModel.js
│       ├── DayModel.js
│       ├── HomeworkModel.js
│       ├── JournalModel.js
│       ├── LessonModel.js
│       ├── MaterialModel.js
│       ├── ParentModel.js
│       ├── RoleModel.js               # ✅ Используется в roles/
│       ├── StudentDataModel.js
│       ├── StudentModel.js
│       ├── StudentParentModel.js
│       ├── SubjectModel.js
│       ├── TeacherModel.js            # ✅ Используется в teachers/
│       ├── TimetabModel.js
│       ├── UserModel.js               # ✅ Используется в users/
│       └── UserRoleModel.js           # ✅ Используется в userroles/
│
└── features/                          # Функции приложения (MVC)
    ├── router.js                      # 🔀 ГЛАВНЫЙ МАРШРУТИЗАТОР
    │
    ├── roles/                         # 🆕 Управление ролями
    │   ├── RoleService.js             # ✅ Сервис (бизнес-логика)
    │   ├── RoleController.js          # ✅ Контролер (обработка запросов)
    │   └── RoleRouter.js              # ✅ Маршруты
    │
    ├── userroles/                     # 🆕 Управление ролями пользователей
    │   ├── UserRoleService.js         # ✅ Сервис (бизнес-логика)
    │   ├── UserRoleController.js      # ✅ Контролер (обработка запросов)
    │   └── UserRoleRouter.js          # ✅ Маршруты
    │
    ├── users/                         # 🆕 Управление пользователями
    │   ├── UserService.js             # ✅ Сервис (бизнес-логика)
    │   ├── UserController.js          # ✅ Контролер (обработка запросов)
    │   └── UserRouter.js              # ✅ Маршруты
    │
    ├── teachers/                      # 🔄 Управление учителями (обновлено)
    │   ├── TeacherService.js          # ✅ Сервис (новый!)
    │   ├── TeacherController.js       # ✅ Контролер (новый!)
    │   ├── TeacherRoutes.js           # Маршруты (существующий)
    │   └── TeacherService.js          # (старый файл, теперь заменен)
    │
    ├── students/                      # Управление студентами (существующий)
    │   ├── StudentServices.js
    │   ├── StudentController.js
    │   └── StudentRouter.js
    │
    ├── auth/                          # Аутентификация (существующий)
    │   ├── authController.js
    │   ├── authMiddleware.js
    │   ├── authRoutes.js
    │   └── authService.js
    │
    ├── temp/                          # Временные данные (существующий)
    │   ├── dict.js
    │   ├── tempController.js
    │   ├── tempRouter.js
    │   ├── tempService.js
    │   └── tempUtils.js
    │
    └── superadmin/                    # Супер-администратор (существующий)
        └── superAdminService.js
```

## Количество файлов

| Категория | Количество |
|-----------|-----------|
| Новые Model-View-Controller наборы | 3 (roles, userroles, users) |
| Обновленные MVC наборы | 1 (teachers) |
| Новые файлы всего | 10 |
| Измененные файлы | 1 (features/router.js) |
| Документация | 2 (ORM_ADAPTATION_GUIDE.md, API_TEST_GUIDE.md) |

## Архитектура MVC

### Request Flow

```
HTTP Request
    ↓
router.js (маршрутизация)
    ↓
*Controller.js (валидация, обработка HTTP)
    ↓
*Service.js (бизнес-логика)
    ↓
*Model.js (работа с БД)
    ↓
Database (PostgreSQL)
    ↓
Database Response
    ↓
*Model.js (форматирование результатов)
    ↓
*Service.js (обработка результатов)
    ↓
*Controller.js (формирование JSON ответа)
    ↓
router.js (отправка ответа)
    ↓
HTTP Response
```

## Подключение маршрутов

**features/router.js**:
```javascript
router.use("/temp", tempRouter);
router.use("/students", studentsRouter);
router.use("/teacher", teacherRouter);
router.use("/userroles", userRoleRouter);      // ✅ Новый
router.use("/users", userRouter);              // ✅ Новый
router.use("/roles", roleRouter);              // ✅ Новый
```

**index.js**:
```javascript
app.use("/api", mainRouter);  // Подключение главного маршрутизатора
```

## API Base URL

```
http://localhost:3000/api
```

## Структура Service-Controller связи

### Пример: Roles

```
RoleRouter.js
├── GET    /         → RoleController.getAllRoles()
├── GET    /:id      → RoleController.getRoleById()
├── POST   /         → RoleController.createRole()
├── PATCH  /:id      → RoleController.updateRole()
└── DELETE /:id      → RoleController.deleteRole()
                          ↓
                    RoleService.js
                    ├── getAllRoles()
                    ├── getRoleById()
                    ├── createRole()
                    ├── updateRole()
                    └── deleteRole()
                          ↓
                    RoleModel.js (lib/models/)
                    ├── findAll()
                    ├── findById()
                    ├── create()
                    ├── update()
                    └── delete()
                          ↓
                    PostgreSQL Database
```

## Модели, используемые в новых сервисах

| Сервис | Модель | Таблица |
|--------|--------|---------|
| RoleService | RoleModel | `roles` |
| UserRoleService | UserRoleModel | `userrole` |
| UserService | UserModel | `users` |
| TeacherService | TeacherModel | `teacher` |

## Обработка ошибок

Все три слоя имеют обработку ошибок:

1. **Model** - Ошибки БД (FK constraint, duplicates и т.д.)
2. **Service** - Логические ошибки, валидация
3. **Controller** - HTTP ошибки, формирование ответов

## Типы ответов

```javascript
// Успешный GET
{ "roles": [...], "teacher": {...} }

// Успешный POST/PATCH
{ "role": {...}, "message": "Role created successfully" }

// Успешный DELETE
{ "message": "Role 1 deleted successfully" }

// Ошибка
{ "error": "Description of error" }
```

## Запуск приложения

```bash
# Установка зависимостей
npm install

# Запуск
npm start

# Тестирование (доступные endpoints)
curl http://localhost:3000/api/users
curl http://localhost:3000/api/roles
curl http://localhost:3000/api/userroles/1
curl http://localhost:3000/api/teachers
```

---

**Статус**: ✅ Полностью готово к использованию

**Последний обновление**: 2024 M12 16

