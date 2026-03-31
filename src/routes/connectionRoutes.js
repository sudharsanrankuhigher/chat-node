const router = require("express").Router();

const connectionController = require("../controllers/connectionController");

router.post("/send-request", connectionController.sendRequest);
router.get("/pending", connectionController.getPendingRequests);
router.post("/respond", connectionController.respondRequest);
router.get("/", connectionController.getConnections);
router.get("/invited", connectionController.getInvitedConnections);

module.exports = router;
