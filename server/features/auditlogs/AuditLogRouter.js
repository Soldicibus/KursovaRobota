import { Router } from "express";
import AuditLogController from "./AuditLogController.js";

const router = Router();

router.get("/", AuditLogController.getAllAuditLogs);

export default router;
