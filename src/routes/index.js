const router = require("express").Router();

const authRoutes = require("./authRoutes");
const connectionRoutes = require("./connectionRoutes");
const chatRoutes = require("./chatRoutes");
const callRoutes = require("./callRoutes");
const walletRoutes = require("./walletRoutes");
const profileRoutes = require("./profileRoutes");
const authMiddleware = require("../middlewares/authMiddleware");

router.use("/auth", authRoutes);
router.use("/connections", authMiddleware, connectionRoutes);
router.use("/chat", authMiddleware, chatRoutes);
router.use("/calls", authMiddleware, callRoutes);
router.use("/wallet", authMiddleware, walletRoutes);
router.use("/profile", authMiddleware, profileRoutes);

module.exports = router;
