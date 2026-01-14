# Документація хуків (Українська)

Цей документ описує всі хуки React Query, створені для додатку, включаючи запити та мутації для кожної сутності. Кожен хук знаходиться у відповідному каталозі під `src/hooks/{entity}/queries/` або `src/hooks/{entity}/mutations/`.

## Класи

### Запити
- **useClasses** (`src/hooks/classes/queries/useClasses.js`): Отримує всі класи за допомогою API `getAllClasses`.
- **useClass** (`src/hooks/classes/queries/useClass.js`): Отримує окремий клас за ID за допомогою API `getClassById`.

### Мутації
- **useCreateClass** (`src/hooks/classes/mutations/useCreateClass.js`): Створює новий клас за допомогою API `createClass` та анулює запит класів.
- **useUpdateClass** (`src/hooks/classes/mutations/useUpdateClass.js`): Оновлює існуючий клас за допомогою API `updateClass` та анулює запит класів.
- **useDeleteClass** (`src/hooks/classes/mutations/useDeleteClass.js`): Видаляє клас за допомогою API `deleteClass` та анулює запит класів.

## Дні

### Запити
- **useDays** (`src/hooks/days/queries/useDays.js`): Отримує всі дні за допомогою API `getAllDays`.
- **useDay** (`src/hooks/days/queries/useDay.js`): Отримує окремий день за ID за допомогою API `getDayById`.

### Мутації
- **useCreateDay** (`src/hooks/days/mutations/useCreateDay.js`): Створює новий день за допомогою API `createDay` та анулює запит днів.
- **useUpdateDay** (`src/hooks/days/mutations/useUpdateDay.js`): Оновлює існуючий день за допомогою API `updateDay` та анулює запит днів.
- **useDeleteDay** (`src/hooks/days/mutations/useDeleteDay.js`): Видаляє день за допомогою API `deleteDay` та анулює запит днів.

## Домашні завдання

### Запити
- **useHomework** (`src/hooks/homework/queries/useHomework.js`): Отримує всі домашні завдання за допомогою API `getAllHomework`.
- **useHomeworkById** (`src/hooks/homework/queries/useHomeworkById.js`): Отримує домашнє завдання за ID за допомогою API `getHomeworkById`.
- **useHomeworkByStudentOrClass** (`src/hooks/homework/queries/useHomeworkByStudentOrClass.js`): Отримує домашні завдання за ID студента або класу за допомогою API `getHomeworkByStudentOrClass`.
- **useHomeworkForTomorrow** (`src/hooks/homework/queries/useHomeworkForTomorrow.js`): Отримує домашні завдання на завтра за допомогою API `getHomeworkForTomorrow`.

### Мутації
- **useCreateHomework** (`src/hooks/homework/mutations/useCreateHomework.js`): Створює нове домашнє завдання за допомогою API `createHomework` та анулює запит домашніх завдань.
- **useUpdateHomework** (`src/hooks/homework/mutations/useUpdateHomework.js`): Оновлює існуюче домашнє завдання за допомогою API `updateHomework` та анулює запит домашніх завдань.
- **useDeleteHomework** (`src/hooks/homework/mutations/useDeleteHomework.js`): Видаляє домашнє завдання за допомогою API `deleteHomework` та анулює запит домашніх завдань.

## Журнали

### Запити
- **useJournals** (`src/hooks/journals/queries/useJournals.js`): Отримує всі журнали за допомогою API `getAllJournals`.
- **useJournal** (`src/hooks/journals/queries/useJournal.js`): Отримує окремий журнал за ID за допомогою API `getJournalById`.
- **useJournalByStudent** (`src/hooks/journals/queries/useJournalByStudent.js`): Отримує журнали за ID студента за допомогою API `getJournalByStudent`.

### Мутації
- **useCreateJournal** (`src/hooks/journals/mutations/useCreateJournal.js`): Створює новий журнал за допомогою API `createJournal` та анулює запит журналів.
- **useUpdateJournal** (`src/hooks/journals/mutations/useUpdateJournal.js`): Оновлює існуючий журнал за допомогою API `updateJournal` та анулює запит журналів.
- **useDeleteJournal** (`src/hooks/journals/mutations/useDeleteJournal.js`): Видаляє журнал за допомогою API `deleteJournal` та анулює запит журналів.

## Уроки

### Запити
- **useLessons** (`src/hooks/lessons/queries/useLessons.js`): Отримує всі уроки за допомогою API `getAllLessons`.
- **useLesson** (`src/hooks/lessons/queries/useLesson.js`): Отримує окремий урок за ID за допомогою API `getLessonById`.

### Мутації
- **useCreateLesson** (`src/hooks/lessons/mutations/useCreateLesson.js`): Створює новий урок за допомогою API `createLesson` та анулює запит уроків.
- **useUpdateLesson** (`src/hooks/lessons/mutations/useUpdateLesson.js`): Оновлює існуючий урок за допомогою API `updateLesson` та анулює запит уроків.
- **useDeleteLesson** (`src/hooks/lessons/mutations/useDeleteLesson.js`): Видаляє урок за допомогою API `deleteLesson` та анулює запит уроків.

## Матеріали

### Запити
- **useMaterials** (`src/hooks/materials/queries/useMaterials.js`): Отримує всі матеріали за допомогою API `getAllMaterials`.
- **useMaterial** (`src/hooks/materials/queries/useMaterial.js`): Отримує окремий матеріал за ID за допомогою API `getMaterialById`.

### Мутації
- **useCreateMaterial** (`src/hooks/materials/mutations/useCreateMaterial.js`): Створює новий матеріал за допомогою API `createMaterial` та анулює запит матеріалів.
- **useUpdateMaterial** (`src/hooks/materials/mutations/useUpdateMaterial.js`): Оновлює існуючий матеріал за допомогою API `updateMaterial` та анулює запит матеріалів.
- **useDeleteMaterial** (`src/hooks/materials/mutations/useDeleteMaterial.js`): Видаляє матеріал за допомогою API `deleteMaterial` та анулює запит матеріалів.

## Батьки

### Запити
- **useParents** (`src/hooks/parents/queries/useParents.js`): Отримує всіх батьків за допомогою API `getParents`.
- **useParent** (`src/hooks/parents/queries/useParent.js`): Отримує окремого батька за ID за допомогою API `getParentById`.

### Мутації
- **useCreateParent** (`src/hooks/parents/mutations/useCreateParent.js`): Створює нового батька за допомогою API `createParent` та анулює запит батьків.
- **useUpdateParent** (`src/hooks/parents/mutations/useUpdateParent.js`): Оновлює існуючого батька за допомогою API `patchParent` та анулює запит батьків.
- **useDeleteParent** (`src/hooks/parents/mutations/useDeleteParent.js`): Видаляє батька за допомогою API `deleteParent` та анулює запит батьків.

## Ролі

### Запити
- **useRoles** (`src/hooks/roles/queries/useRoles.js`): Отримує всі ролі за допомогою API `getAllRoles`.
- **useRole** (`src/hooks/roles/queries/useRole.js`): Отримує окрему роль за ID за допомогою API `getRoleById`.

### Мутації
- **useCreateRole** (`src/hooks/roles/mutations/useCreateRole.js`): Створює нову роль за допомогою API `createRole` та анулює запит ролей.
- **useUpdateRole** (`src/hooks/roles/mutations/useUpdateRole.js`): Оновлює існуючу роль за допомогою API `updateRole` та анулює запит ролей.
- **useDeleteRole** (`src/hooks/roles/mutations/useDeleteRole.js`): Видаляє роль за допомогою API `deleteRole` та анулює запит ролей.

## Дані студентів

### Запити
- **useStudentData** (`src/hooks/studentdata/queries/useStudentData.js`): Отримує всі дані студентів за допомогою API `getAllStudentData`.
- **useStudentDataById** (`src/hooks/studentdata/queries/useStudentDataById.js`): Отримує дані студента за ID за допомогою API `getStudentDataById`.
- **useStudentDataMarks7d** (`src/hooks/studentdata/queries/useStudentDataMarks7d.js`): Отримує оцінки даних студента за останні 7 днів за ID студента за допомогою API `getStudentDataMarks7d`.

### Мутації
- **useCreateStudentData** (`src/hooks/studentdata/mutations/useCreateStudentData.js`): Створює нові дані студента за допомогою API `createStudentData` та анулює запит даних студентів.
- **useUpdateStudentData** (`src/hooks/studentdata/mutations/useUpdateStudentData.js`): Оновлює існуючі дані студента за допомогою API `updateStudentData` та анулює запит даних студентів.
- **useDeleteStudentData** (`src/hooks/studentdata/mutations/useDeleteStudentData.js`): Видаляє дані студента за допомогою API `deleteStudentData` та анулює запит даних студентів.

## Батьки студентів

### Запити
- **useParentsByStudent** (`src/hooks/studentparents/queries/useParentsByStudent.js`): Отримує батьків за ID студента за допомогою API `getParentsByStudentId`.

### Мутації
- **useAssignParentToStudent** (`src/hooks/studentparents/mutations/useAssignParentToStudent.js`): Призначає батька студенту за допомогою API `assignParentToStudent` та анулює запит батьків студентів.
- **useUnassignParentFromStudent** (`src/hooks/studentparents/mutations/useUnassignParentFromStudent.js`): Відміняє призначення батька студенту за допомогою API `unassignParentFromStudent` та анулює запит батьків студентів.

## Студенти

### Запити
- **useStudents** (`src/hooks/students/queries/useStudents.js`): Отримує всіх студентів за допомогою API `getAllStudents`.
- **useStudent** (`src/hooks/students/queries/useStudent.js`): Отримує окремого студента за ID за допомогою API `getStudentById`.
- **useStudentAVGAbove7** (`src/hooks/students/queries/useStudentAVGAbove7.js`): Отримує студентів із середнім балом вище 7 за допомогою API `getStudentAVGAbove7`.
- **useStudentByClass** (`src/hooks/students/queries/useStudentByClass.js`): Отримує студентів за класом за допомогою API `getStudentByClass`.
- **useStudentRanking** (`src/hooks/students/queries/useStudentRanking.js`): Отримує рейтинг студентів за допомогою API `getStudentRanking`.
- **useStudentByParent** (`src/hooks/students/queries/useStudentByParent.js`): Отримує студентів за ID батька за допомогою API `getStudentByParentId`.
- **useStudentGradesAndAbsences** (`src/hooks/students/queries/useStudentGradesAndAbsences.js`): Отримує оцінки та відсутності студента за допомогою API `getGradesAndAbsences`.
- **useStudentMarks** (`src/hooks/students/queries/useStudentMarks.js`): Отримує оцінки студента за допомогою API `getStudentsMarks`.
- **useStudentAttendance** (`src/hooks/students/queries/useStudentAttendance.js`): Отримує відвідуваність студента за допомогою API `getStudentsAttendance`.
- **useStudentDayPlan** (`src/hooks/students/queries/useStudentDayPlan.js`): Отримує денний план студента за допомогою API `getStudentsDayPlan`.

### Мутації
- **useCreateStudent** (`src/hooks/students/mutations/useCreateStudent.js`): Створює нового студента за допомогою API `createStudent` та анулює запит студентів.
- **useUpdateStudent** (`src/hooks/students/mutations/useUpdateStudent.js`): Оновлює існуючого студента за допомогою API `patchStudent` та анулює запит студентів.
- **useDeleteStudent** (`src/hooks/students/mutations/useDeleteStudent.js`): Видаляє студента за допомогою API `deleteStudent` та анулює запит студентів.

## Предмети

### Запити
- **useSubjects** (`src/hooks/subjects/queries/useSubjects.js`): Отримує всі предмети за допомогою API `getAllSubjects`.

### Мутації
- **useCreateSubject** (`src/hooks/subjects/mutations/useCreateSubject.js`): Створює новий предмет за допомогою API `createSubject` та анулює запит предметів.
- **useDeleteSubject** (`src/hooks/subjects/mutations/useDeleteSubject.js`): Видаляє предмет за допомогою API `deleteSubject` та анулює запит предметів.

## Викладачі

### Запити
- **useTeachers** (`src/hooks/teachers/queries/useTeachers.js`): Отримує всіх викладачів за допомогою API `getTeachers`.
- **useTeacher** (`src/hooks/teachers/queries/useTeacher.js`): Отримує окремого викладача за ID за допомогою API `getTeacherById`.
- **useTeacherSalaryReport** (`src/hooks/teachers/queries/useTeacherSalaryReport.js`): Отримує звіт про зарплату викладачів за допомогою API `getTeacherSalaryReport`.
- **useTeachersWithClasses** (`src/hooks/teachers/queries/useTeachersWithClasses.js`): Отримує викладачів із класами за допомогою API `getTeachersWithClasses`.

### Мутації
- **useCreateTeacher** (`src/hooks/teachers/mutations/useCreateTeacher.js`): Створює нового викладача за допомогою API `createTeacher` та анулює запит викладачів.
- **useUpdateTeacher** (`src/hooks/teachers/mutations/useUpdateTeacher.js`): Оновлює існуючого викладача за допомогою API `patchTeacher` та анулює запит викладачів.
- **useDeleteTeacher** (`src/hooks/teachers/mutations/useDeleteTeacher.js`): Видаляє викладача за допомогою API `deleteTeacher` та анулює запит викладачів.

## Розклади

### Запити
- **useTimetables** (`src/hooks/timetables/queries/useTimetables.js`): Отримує всі розклади за допомогою API `getAllTimetables`.
- **useTimetable** (`src/hooks/timetables/queries/useTimetable.js`): Отримує окремий розклад за ID за допомогою API `getTimetableById`.
- **useWeeklyTimetable** (`src/hooks/timetables/queries/useWeeklyTimetable.js`): Отримує тижневий розклад за ID за допомогою API `getWeeklyTimetable`.
- **useTimetableByStudent** (`src/hooks/timetables/queries/useTimetableByStudent.js`): Отримує розклад за ID студента за допомогою API `getTimetableByStudentId`.

### Мутації
- **useCreateTimetable** (`src/hooks/timetables/mutations/useCreateTimetable.js`): Створює новий розклад за допомогою API `createTimetable` та анулює запит розкладів.
- **useUpdateTimetable** (`src/hooks/timetables/mutations/useUpdateTimetable.js`): Оновлює існуючий розклад за допомогою API `updateTimetable` та анулює запит розкладів.
- **useDeleteTimetable** (`src/hooks/timetables/mutations/useDeleteTimetable.js`): Видаляє розклад за допомогою API `deleteTimetable` та анулює запит розкладів.

## Ролі користувачів

### Запити
- **useUserRoles** (`src/hooks/userroles/queries/useUserRoles.js`): Отримує ролі за ID користувача за допомогою API `getRolesByUserId`.
- **useUserRole** (`src/hooks/userroles/queries/useUserRole.js`): Отримує роль користувача за ID користувача за допомогою API `getUserRole`.

### Мутації
- **useAssignRole** (`src/hooks/userroles/mutations/useAssignRole.js`): Призначає роль користувачу за допомогою API `assignRole` та анулює запит ролей користувачів.
- **useRemoveRoleFromUser** (`src/hooks/userroles/mutations/useRemoveRoleFromUser.js`): Видаляє роль від користувача за допомогою API `removeRoleFromUser` та анулює запит ролей користувачів.

## Користувачі

### Запити
- **useUsers** (`src/hooks/users/queries/useUsers.js`): Отримує всіх користувачів за допомогою API `getAllUsers`.
- **useUser** (`src/hooks/users/queries/useUser.js`): Отримує окремого користувача за ID за допомогою API `getUserById`.
- **useUserData** (`src/hooks/users/queries/useUserData.js`): Отримує дані користувача за ID за допомогою API `getUserData`.

### Мутації
- **useCreateUser** (`src/hooks/users/mutations/useCreateUser.js`): Створює нового користувача за допомогою API `createUser` та анулює запит користувачів.
- **useResetPassword** (`src/hooks/users/mutations/useResetPassword.js`): Скидає пароль користувача за допомогою API `resetPassword` та анулює запит користувачів.
- **useUpdateUser** (`src/hooks/users/mutations/useUpdateUser.js`): Оновлює існуючого користувача за допомогою API `updateUser` та анулює запит користувачів.
- **useDeleteUser** (`src/hooks/users/mutations/useDeleteUser.js`): Видаляє користувача за допомогою API `deleteUser` та анулює запит користувачів.