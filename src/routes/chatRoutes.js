const router = require("express").Router();

const chatController = require("../controllers/chatController");

router.get("/contacts", chatController.getContacts);
router.post("/send", chatController.sendMessage);
router.get("/messages/:chatId", chatController.getMessages);

module.exports = router;
