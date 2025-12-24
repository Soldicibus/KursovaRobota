import { ukToLatMap } from "./dict.js";
import bcrypt from "bcrypt";
import crypto from "node:crypto";

const SALT_ROUNDS = 12;
class TempUtils {
  tranlateToLatin(text) {
    return text.replace(
      /[А-Яа-яЄєІіЇїҐґЬь'’]/g,
      (char) => ukToLatMap[char] || "",
    );
  }
  generatePassword(length = 8) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    const bytes = crypto.randomBytes(length);

    return Array.from(bytes, (b) => chars[b % chars.length]).join("");
  }
  async hashPassword(password) {
    return bcrypt.hash(password, SALT_ROUNDS);
  }
}
export default new TempUtils();
