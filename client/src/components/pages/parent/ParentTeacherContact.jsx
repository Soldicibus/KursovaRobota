import React from 'react';
import { useClass } from '../../../hooks/classes/queries/useClass';
import { useTeacher } from '../../../hooks/teachers/queries/useTeacher';

// Helper component to display teacher details
const TeacherCard = ({ teacherId }) => {
  const { data: teacher, isLoading, error } = useTeacher(teacherId);

  if (isLoading) {
    return <div className="loading-state">Завантаження даних вчителя...</div>;
  }

  if (error) {
    return <div className="error-state">Помилка при завантаженні: {error.message}</div>;
  }

  if (!teacher) {
    return <div className="empty-state">Вчителя не знайдено.</div>;
  }

  return (
    <div className="teacher-info" style={{ marginTop: '20px', padding: '15px', border: '1px solid #ddd', borderRadius: '8px' }}>
      <h3 style={{ marginTop: 0 }}>Класний керівник</h3>
      <div className="info-row" style={{ marginBottom: '10px' }}>
        <strong>ПІБ:</strong> {teacher.teacher_surname} {teacher.teacher_name} {teacher.teacher_patronym}
      </div>
      <div className="info-row" style={{ marginBottom: '10px' }}>
        <strong>Телефон:</strong> {teacher.teacher_phone || 'Не вказано'}
      </div>
    </div>
  );
};

export default function ParentTeacherContact({ studentClass }) {
  if (!studentClass) {
    return (
      <div className="message-container">
        <p>Учень не прив'язаний до жодного класу.</p>
      </div>
    );
  }

  const { data: classData, isLoading, error } = useClass(studentClass);

  if (isLoading) {
    return <div>Завантаження інформації про клас...</div>;
  }

  if (error) {
    return <div>Помилка при отриманні даних класу: {error.message}</div>;
  }

  if (!classData) {
    return <div>Інформацію про клас "{studentClass}" не знайдено.</div>;
  }

  const mainTeacherId = classData.class_mainteacher;

  if (!mainTeacherId) {
    return <div>У класі "{studentClass}" не призначено класного керівника.</div>;
  }

  return <TeacherCard teacherId={mainTeacherId} />;
}
