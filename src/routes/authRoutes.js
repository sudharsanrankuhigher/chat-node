const router = require("express").Router();

const authController = require("../controllers/authController");

router.post("/send-otp", authController.sendOtp);
router.post("/verify-otp", authController.verifyOtp);
router.post("/register", authController.register);

module.exports = router;
