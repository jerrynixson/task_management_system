from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Task
from .serializers import TaskSerializer

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = Task.objects.filter(assigned_user=user)
        
        # Filter by status if provided
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)

        return queryset

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Update task status if provided
        status_param = request.data.get('status')
        if status_param:
            instance.status = status_param
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        return Response(serializer.data, status=status.HTTP_200_OK)
    
    def perform_update(self, serializer):
        super().perform_update(serializer)
        # Notify WebSocket clients about the task update
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            'task_updates',
            {
                'type': 'task_message',
                'message': f'Task {serializer.instance.id} has been updated to {serializer.instance.status}'
            }
        )
