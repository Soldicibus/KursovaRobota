import { Router } from "express";
import JournalController from "./JournalController.js";

const router = Router();

router.get("/", JournalController.getAllJournals);
router.get("/student/:studentId", JournalController.getJournalByStudent);
router.get("/:id", JournalController.getJournalById);
router.post("/", JournalController.createJournal);
router.patch("/:id", JournalController.updateJournal);
router.delete("/:id", JournalController.deleteJournal);

export default router;

