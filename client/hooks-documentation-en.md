# Hooks Documentation (English)

This document describes all the React Query hooks created for the application, including queries and mutations for each entity. Each hook is located in its respective directory under `src/hooks/{entity}/queries/` or `src/hooks/{entity}/mutations/`.

## Classes

### Queries
- **useClasses** (`src/hooks/classes/queries/useClasses.js`): Fetches all classes using the `getAllClasses` API.
- **useClass** (`src/hooks/classes/queries/useClass.js`): Fetches a single class by ID using the `getClassById` API.

### Mutations
- **useCreateClass** (`src/hooks/classes/mutations/useCreateClass.js`): Creates a new class using the `createClass` API and invalidates the classes query.
- **useUpdateClass** (`src/hooks/classes/mutations/useUpdateClass.js`): Updates an existing class using the `updateClass` API and invalidates the classes query.
- **useDeleteClass** (`src/hooks/classes/mutations/useDeleteClass.js`): Deletes a class using the `deleteClass` API and invalidates the classes query.

## Days

### Queries
- **useDays** (`src/hooks/days/queries/useDays.js`): Fetches all days using the `getAllDays` API.
- **useDay** (`src/hooks/days/queries/useDay.js`): Fetches a single day by ID using the `getDayById` API.

### Mutations
- **useCreateDay** (`src/hooks/days/mutations/useCreateDay.js`): Creates a new day using the `createDay` API and invalidates the days query.
- **useUpdateDay** (`src/hooks/days/mutations/useUpdateDay.js`): Updates an existing day using the `updateDay` API and invalidates the days query.
- **useDeleteDay** (`src/hooks/days/mutations/useDeleteDay.js`): Deletes a day using the `deleteDay` API and invalidates the days query.

## Homework

### Queries
- **useHomework** (`src/hooks/homework/queries/useHomework.js`): Fetches all homework using the `getAllHomework` API.
- **useHomeworkById** (`src/hooks/homework/queries/useHomeworkById.js`): Fetches homework by ID using the `getHomeworkById` API.
- **useHomeworkByStudentOrClass** (`src/hooks/homework/queries/useHomeworkByStudentOrClass.js`): Fetches homework by student or class ID using the `getHomeworkByStudentOrClass` API.
- **useHomeworkForTomorrow** (`src/hooks/homework/queries/useHomeworkForTomorrow.js`): Fetches homework for tomorrow using the `getHomeworkForTomorrow` API.

### Mutations
- **useCreateHomework** (`src/hooks/homework/mutations/useCreateHomework.js`): Creates new homework using the `createHomework` API and invalidates the homework query.
- **useUpdateHomework** (`src/hooks/homework/mutations/useUpdateHomework.js`): Updates existing homework using the `updateHomework` API and invalidates the homework query.
- **useDeleteHomework** (`src/hooks/homework/mutations/useDeleteHomework.js`): Deletes homework using the `deleteHomework` API and invalidates the homework query.

## Journals

### Queries
- **useJournals** (`src/hooks/journals/queries/useJournals.js`): Fetches all journals using the `getAllJournals` API.
- **useJournal** (`src/hooks/journals/queries/useJournal.js`): Fetches a single journal by ID using the `getJournalById` API.
- **useJournalByStudent** (`src/hooks/journals/queries/useJournalByStudent.js`): Fetches journals by student ID using the `getJournalByStudent` API.

### Mutations
- **useCreateJournal** (`src/hooks/journals/mutations/useCreateJournal.js`): Creates a new journal using the `createJournal` API and invalidates the journals query.
- **useUpdateJournal** (`src/hooks/journals/mutations/useUpdateJournal.js`): Updates an existing journal using the `updateJournal` API and invalidates the journals query.
- **useDeleteJournal** (`src/hooks/journals/mutations/useDeleteJournal.js`): Deletes a journal using the `deleteJournal` API and invalidates the journals query.

## Lessons

### Queries
- **useLessons** (`src/hooks/lessons/queries/useLessons.js`): Fetches all lessons using the `getAllLessons` API.
- **useLesson** (`src/hooks/lessons/queries/useLesson.js`): Fetches a single lesson by ID using the `getLessonById` API.

### Mutations
- **useCreateLesson** (`src/hooks/lessons/mutations/useCreateLesson.js`): Creates a new lesson using the `createLesson` API and invalidates the lessons query.
- **useUpdateLesson** (`src/hooks/lessons/mutations/useUpdateLesson.js`): Updates an existing lesson using the `updateLesson` API and invalidates the lessons query.
- **useDeleteLesson** (`src/hooks/lessons/mutations/useDeleteLesson.js`): Deletes a lesson using the `deleteLesson` API and invalidates the lessons query.

## Materials

### Queries
- **useMaterials** (`src/hooks/materials/queries/useMaterials.js`): Fetches all materials using the `getAllMaterials` API.
- **useMaterial** (`src/hooks/materials/queries/useMaterial.js`): Fetches a single material by ID using the `getMaterialById` API.

### Mutations
- **useCreateMaterial** (`src/hooks/materials/mutations/useCreateMaterial.js`): Creates new material using the `createMaterial` API and invalidates the materials query.
- **useUpdateMaterial** (`src/hooks/materials/mutations/useUpdateMaterial.js`): Updates existing material using the `updateMaterial` API and invalidates the materials query.
- **useDeleteMaterial** (`src/hooks/materials/mutations/useDeleteMaterial.js`): Deletes material using the `deleteMaterial` API and invalidates the materials query.

## Parents

### Queries
- **useParents** (`src/hooks/parents/queries/useParents.js`): Fetches all parents using the `getParents` API.
- **useParent** (`src/hooks/parents/queries/useParent.js`): Fetches a single parent by ID using the `getParentById` API.

### Mutations
- **useCreateParent** (`src/hooks/parents/mutations/useCreateParent.js`): Creates a new parent using the `createParent` API and invalidates the parents query.
- **useUpdateParent** (`src/hooks/parents/mutations/useUpdateParent.js`): Updates an existing parent using the `patchParent` API and invalidates the parents query.
- **useDeleteParent** (`src/hooks/parents/mutations/useDeleteParent.js`): Deletes a parent using the `deleteParent` API and invalidates the parents query.

## Roles

### Queries
- **useRoles** (`src/hooks/roles/queries/useRoles.js`): Fetches all roles using the `getAllRoles` API.
- **useRole** (`src/hooks/roles/queries/useRole.js`): Fetches a single role by ID using the `getRoleById` API.

### Mutations
- **useCreateRole** (`src/hooks/roles/mutations/useCreateRole.js`): Creates a new role using the `createRole` API and invalidates the roles query.
- **useUpdateRole** (`src/hooks/roles/mutations/useUpdateRole.js`): Updates an existing role using the `updateRole` API and invalidates the roles query.
- **useDeleteRole** (`src/hooks/roles/mutations/useDeleteRole.js`): Deletes a role using the `deleteRole` API and invalidates the roles query.

## Student Data

### Queries
- **useStudentData** (`src/hooks/studentdata/queries/useStudentData.js`): Fetches all student data using the `getAllStudentData` API.
- **useStudentDataById** (`src/hooks/studentdata/queries/useStudentDataById.js`): Fetches student data by ID using the `getStudentDataById` API.
- **useStudentDataMarks7d** (`src/hooks/studentdata/queries/useStudentDataMarks7d.js`): Fetches student data marks for the last 7 days by student ID using the `getStudentDataMarks7d` API.

### Mutations
- **useCreateStudentData** (`src/hooks/studentdata/mutations/useCreateStudentData.js`): Creates new student data using the `createStudentData` API and invalidates the studentdata query.
- **useUpdateStudentData** (`src/hooks/studentdata/mutations/useUpdateStudentData.js`): Updates existing student data using the `updateStudentData` API and invalidates the studentdata query.
- **useDeleteStudentData** (`src/hooks/studentdata/mutations/useDeleteStudentData.js`): Deletes student data using the `deleteStudentData` API and invalidates the studentdata query.

## Student Parents

### Queries
- **useParentsByStudent** (`src/hooks/studentparents/queries/useParentsByStudent.js`): Fetches parents by student ID using the `getParentsByStudentId` API.

### Mutations
- **useAssignParentToStudent** (`src/hooks/studentparents/mutations/useAssignParentToStudent.js`): Assigns a parent to a student using the `assignParentToStudent` API and invalidates the studentparents query.
- **useUnassignParentFromStudent** (`src/hooks/studentparents/mutations/useUnassignParentFromStudent.js`): Unassigns a parent from a student using the `unassignParentFromStudent` API and invalidates the studentparents query.

## Students

### Queries
- **useStudents** (`src/hooks/students/queries/useStudents.js`): Fetches all students using the `getAllStudents` API.
- **useStudent** (`src/hooks/students/queries/useStudent.js`): Fetches a single student by ID using the `getStudentById` API.
- **useStudentAVGAbove7** (`src/hooks/students/queries/useStudentAVGAbove7.js`): Fetches students with average above 7 using the `getStudentAVGAbove7` API.
- **useStudentByClass** (`src/hooks/students/queries/useStudentByClass.js`): Fetches students by class using the `getStudentByClass` API.
- **useStudentRanking** (`src/hooks/students/queries/useStudentRanking.js`): Fetches student ranking using the `getStudentRanking` API.
- **useStudentByParent** (`src/hooks/students/queries/useStudentByParent.js`): Fetches students by parent ID using the `getStudentByParentId` API.
- **useStudentGradesAndAbsences** (`src/hooks/students/queries/useStudentGradesAndAbsences.js`): Fetches student grades and absences using the `getGradesAndAbsences` API.
- **useStudentMarks** (`src/hooks/students/queries/useStudentMarks.js`): Fetches student marks using the `getStudentsMarks` API.
- **useStudentAttendance** (`src/hooks/students/queries/useStudentAttendance.js`): Fetches student attendance using the `getStudentsAttendance` API.
- **useStudentDayPlan** (`src/hooks/students/queries/useStudentDayPlan.js`): Fetches student day plan using the `getStudentsDayPlan` API.

### Mutations
- **useCreateStudent** (`src/hooks/students/mutations/useCreateStudent.js`): Creates a new student using the `createStudent` API and invalidates the students query.
- **useUpdateStudent** (`src/hooks/students/mutations/useUpdateStudent.js`): Updates an existing student using the `patchStudent` API and invalidates the students query.
- **useDeleteStudent** (`src/hooks/students/mutations/useDeleteStudent.js`): Deletes a student using the `deleteStudent` API and invalidates the students query.

## Subjects

### Queries
- **useSubjects** (`src/hooks/subjects/queries/useSubjects.js`): Fetches all subjects using the `getAllSubjects` API.

### Mutations
- **useCreateSubject** (`src/hooks/subjects/mutations/useCreateSubject.js`): Creates a new subject using the `createSubject` API and invalidates the subjects query.
- **useDeleteSubject** (`src/hooks/subjects/mutations/useDeleteSubject.js`): Deletes a subject using the `deleteSubject` API and invalidates the subjects query.

## Teachers

### Queries
- **useTeachers** (`src/hooks/teachers/queries/useTeachers.js`): Fetches all teachers using the `getTeachers` API.
- **useTeacher** (`src/hooks/teachers/queries/useTeacher.js`): Fetches a single teacher by ID using the `getTeacherById` API.
- **useTeacherSalaryReport** (`src/hooks/teachers/queries/useTeacherSalaryReport.js`): Fetches teacher salary report using the `getTeacherSalaryReport` API.
- **useTeachersWithClasses** (`src/hooks/teachers/queries/useTeachersWithClasses.js`): Fetches teachers with classes using the `getTeachersWithClasses` API.

### Mutations
- **useCreateTeacher** (`src/hooks/teachers/mutations/useCreateTeacher.js`): Creates a new teacher using the `createTeacher` API and invalidates the teachers query.
- **useUpdateTeacher** (`src/hooks/teachers/mutations/useUpdateTeacher.js`): Updates an existing teacher using the `patchTeacher` API and invalidates the teachers query.
- **useDeleteTeacher** (`src/hooks/teachers/mutations/useDeleteTeacher.js`): Deletes a teacher using the `deleteTeacher` API and invalidates the teachers query.

## Timetables

### Queries
- **useTimetables** (`src/hooks/timetables/queries/useTimetables.js`): Fetches all timetables using the `getAllTimetables` API.
- **useTimetable** (`src/hooks/timetables/queries/useTimetable.js`): Fetches a single timetable by ID using the `getTimetableById` API.
- **useWeeklyTimetable** (`src/hooks/timetables/queries/useWeeklyTimetable.js`): Fetches weekly timetable by ID using the `getWeeklyTimetable` API.
- **useTimetableByStudent** (`src/hooks/timetables/queries/useTimetableByStudent.js`): Fetches timetable by student ID using the `getTimetableByStudentId` API.

### Mutations
- **useCreateTimetable** (`src/hooks/timetables/mutations/useCreateTimetable.js`): Creates a new timetable using the `createTimetable` API and invalidates the timetables query.
- **useUpdateTimetable** (`src/hooks/timetables/mutations/useUpdateTimetable.js`): Updates an existing timetable using the `updateTimetable` API and invalidates the timetables query.
- **useDeleteTimetable** (`src/hooks/timetables/mutations/useDeleteTimetable.js`): Deletes a timetable using the `deleteTimetable` API and invalidates the timetables query.

## User Roles

### Queries
- **useUserRoles** (`src/hooks/userroles/queries/useUserRoles.js`): Fetches roles by user ID using the `getRolesByUserId` API.
- **useUserRole** (`src/hooks/userroles/queries/useUserRole.js`): Fetches user role by user ID using the `getUserRole` API.

### Mutations
- **useAssignRole** (`src/hooks/userroles/mutations/useAssignRole.js`): Assigns a role to a user using the `assignRole` API and invalidates the user-roles query.
- **useRemoveRoleFromUser** (`src/hooks/userroles/mutations/useRemoveRoleFromUser.js`): Removes a role from a user using the `removeRoleFromUser` API and invalidates the user-roles query.

## Users

### Queries
- **useUsers** (`src/hooks/users/queries/useUsers.js`): Fetches all users using the `getAllUsers` API.
- **useUser** (`src/hooks/users/queries/useUser.js`): Fetches a single user by ID using the `getUserById` API.
- **useUserData** (`src/hooks/users/queries/useUserData.js`): Fetches user data by ID using the `getUserData` API.

### Mutations
- **useCreateUser** (`src/hooks/users/mutations/useCreateUser.js`): Creates a new user using the `createUser` API and invalidates the users query.
- **useResetPassword** (`src/hooks/users/mutations/useResetPassword.js`): Resets user password using the `resetPassword` API and invalidates the users query.
- **useUpdateUser** (`src/hooks/users/mutations/useUpdateUser.js`): Updates an existing user using the `updateUser` API and invalidates the users query.
- **useDeleteUser** (`src/hooks/users/mutations/useDeleteUser.js`): Deletes a user using the `deleteUser` API and invalidates the users query.