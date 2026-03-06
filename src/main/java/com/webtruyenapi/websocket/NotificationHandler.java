package com.webtruyenapi.websocket;

import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Controller
@Slf4j
public class NotificationHandler {
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationHandler(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    @MessageMapping("/notifications/send")
    @SendTo("/topic/notifications")
    public Map<String, Object> sendNotification(Map<String, Object> message) {
        log.info("Notification sent: {}", message);
        message.put("timestamp", LocalDateTime.now().toString());
        return message;
    }

    // Send notification to specific user
    public void sendNotificationToUser(String userId, Map<String, Object> notification) {
        notification.put("timestamp", LocalDateTime.now().toString());
        messagingTemplate.convertAndSendToUser(userId, "/queue/notifications", notification);
    }

    // Broadcast notification to all users
    public void broadcastNotification(Map<String, Object> notification) {
        notification.put("timestamp", LocalDateTime.now().toString());
        messagingTemplate.convertAndSend("/topic/notifications", notification);
    }
}

@RestController
@RequestMapping("/api/notifications")
@Slf4j
class NotificationRestController {
    private final NotificationHandler notificationHandler;

    public NotificationRestController(NotificationHandler notificationHandler) {
        this.notificationHandler = notificationHandler;
    }

    @PostMapping("/send")
    public Map<String, String> sendNotification(@RequestBody Map<String, Object> notification) {
        notificationHandler.broadcastNotification(notification);
        return Map.of("message", "Notification sent successfully");
    }

    @PostMapping("/send-to-user")
    public Map<String, String> sendNotificationToUser(
            @RequestBody Map<String, Object> payload) {
        String userId = (String) payload.get("userId");
        Map<String, Object> notification = (Map<String, Object>) payload.get("notification");
        notificationHandler.sendNotificationToUser(userId, notification);
        return Map.of("message", "Notification sent to user successfully");
    }
}
