import AuditLogModel from "../../lib/models/AuditLogModel.js";

class AuditLogService {
  static async getAllAuditLogs(db) {
    try {
      const result = await AuditLogModel.findAll(db);
      return result;
    } catch (error) {
      throw error;
    }
  }
}

export default AuditLogService;
