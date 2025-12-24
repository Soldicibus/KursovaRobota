import { Router } from "express";
import DayController from "./DayController.js";

const router = Router();

router.get("/", DayController.getAllDays);
router.get("/:id", DayController.getDayById);
router.post("/", DayController.createDay);
router.patch("/:id", DayController.updateDay);
router.delete("/:id", DayController.deleteDay);

export default router;

