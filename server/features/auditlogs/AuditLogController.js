import AuditLogService from "./AuditLogService.js";
import { bouncer } from "../../lib/db-helpers/bouncer.js";

class AuditLogController {
  static async getAllAuditLogs(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await AuditLogService.getAllAuditLogs(db);
      return { auditlogs: result };
    });
  }
}

export default AuditLogController;
