const router = require("express").Router();

const walletController = require("../controllers/walletController");

router.post("/add-money", walletController.addMoney);
router.get("/", walletController.getWallet);

module.exports = router;
