# your_app_name/consumers.py
import json
from channels.generic.websocket import AsyncWebsocketConsumer

class TaskConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add("task_updates", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard("task_updates", self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        # Handle received data
        await self.channel_layer.group_send(
            "task_updates",
            {
                "type": "task_update",
                "message": data['message']
            }
        )

    async def task_update(self, event):
        message = event['message']
        await self.send(text_data=json.dumps({
            'message': message
        }))
