# apps/interactions/models.py
from django.db import models
from django.forms import ValidationError
from apps.users.models import User
from django.conf import settings
from django.db.models.signals import post_save, post_delete, pre_save
from django.dispatch import receiver
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType

class Notification(models.Model):
    TYPE_CHOICES = [
        ('NEW_REQUEST', 'New Service Request'),
        ('REQUEST_ACCEPTED', 'Request Accepted'),
        ('REQUEST_REJECTED', 'Request Rejected'),
        ('NEW_UPVOTE', 'New Upvote'),
        ('REPORT_UPDATE', 'Report Update'),
        ('SYSTEM', 'System Alert'),
    ]

    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    title = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, null=True, blank=True)
    object_id = models.PositiveIntegerField(null=True, blank=True)
    content_object = GenericForeignKey('content_type', 'object_id')

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"To {self.recipient.email}: {self.title}"

class ServiceRequest(models.Model):
    STATUS_CHOICES = [('Pending', 'Pending'), ('Accepted', 'Accepted'), ('Rejected', 'Rejected')]

    cwsn_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_requests')
    caregiver = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='received_requests')
    child = models.ForeignKey('users.ChildProfile', on_delete=models.CASCADE, related_name='service_requests')
    service = models.ForeignKey('services.Service', on_delete=models.CASCADE, related_name='requests')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='Pending')
    note = models.TextField(blank=True, help_text="Optional note from the parent when creating the request.")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('cwsn_user', 'child', 'service')

    def __str__(self):
        return f"Request from {self.cwsn_user.email} for {self.service.title}"
    
    def clean(self):
        super().clean()
        if self.child and self.cwsn_user:
            if self.child.parent != self.cwsn_user:
                raise ValidationError({
                    'child': 'The selected child does not belong to the selected CWSN user.'
                })

@receiver(post_save, sender=ServiceRequest)
def populate_caregiver(sender, instance, created, **kwargs):
    if created:
        instance.caregiver = instance.service.caregiver
        instance.save()

class Report(models.Model):
    STATUS_CHOICES = [('Open', 'Open'), ('Resolved', 'Resolved'), ('Dismissed', 'Dismissed')]
    
    reporter = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='filed_reports')
    reported_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reports_against')
    reason = models.TextField()
    region_of_incident = models.ForeignKey('common.Region', on_delete=models.SET_NULL, null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='Open')
    created_at = models.DateTimeField(auto_now_add=True)
    moderator_action = models.TextField(blank=True, null=True, help_text="[Moderator only] Action taken or notes.")

    def __str__(self):
        return f"Report against {self.reported_user.email} by {self.reporter.email}"

@receiver(post_save, sender=Report)
def populate_report_region(sender, instance, created, **kwargs):
    if created and instance.reported_user.is_caregiver:
        try:
            instance.region_of_incident = instance.reported_user.caregiver_profile.region
            instance.save()
        except:
            pass

# --- UPDATED UPVOTE MODEL ---
class Upvote(models.Model):
    voter = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='given_upvotes')
    # CHANGED: 'caregiver' is now 'service'
    service = models.ForeignKey('services.Service', on_delete=models.CASCADE, related_name='received_upvotes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['voter', 'service'], name='unique_upvote')
        ]

@receiver(post_save, sender=Upvote)
def increment_upvote_count(sender, instance, created, **kwargs):
    if created:
        instance.service.upvote_count += 1
        instance.service.save()

@receiver(post_delete, sender=Upvote)
def decrement_upvote_count(sender, instance, **kwargs):
    try:
        if instance.service.upvote_count > 0:
            instance.service.upvote_count -= 1
            instance.service.save()
    except Exception:
        pass

@receiver(post_save, sender=Upvote)
def notify_caregiver_on_upvote(sender, instance, created, **kwargs):
    if created:
        Notification.objects.create(
            recipient=instance.service.caregiver,
            notification_type='NEW_UPVOTE',
            title='New upvote on your service!',
            message=f'{instance.voter.cwsn_profile.name} upvoted your service: {instance.service.title}.',
            content_object=instance
        )

# 2. Trigger for Service Requests (Creation and Status Updates)
@receiver(pre_save, sender=ServiceRequest)
def track_request_status_change(sender, instance, **kwargs):
    if instance.pk:
        try:
            old_instance = ServiceRequest.objects.get(pk=instance.pk)
            instance._old_status = old_instance.status
        except ServiceRequest.DoesNotExist:
            instance._old_status = None
    else:
        instance._old_status = None

@receiver(post_save, sender=ServiceRequest)
def notify_on_service_request(sender, instance, created, **kwargs):
    if created:
        Notification.objects.create(
            recipient=instance.caregiver,
            notification_type='NEW_REQUEST',
            title='New Service Request',
            message=f'{instance.cwsn_user.cwsn_profile.name} has requested your service: {instance.service.title}.',
            content_object=instance
        )
    else:
        old_status = getattr(instance, '_old_status', None)
        if old_status and old_status != instance.status:
            if instance.status == 'Accepted':
                Notification.objects.create(
                    recipient=instance.cwsn_user,
                    notification_type='REQUEST_ACCEPTED',
                    title='Request Accepted!',
                    message=f'{instance.caregiver.caregiver_profile.name} accepted your request for {instance.service.title}.',
                    content_object=instance
                )
            elif instance.status == 'Rejected':
                Notification.objects.create(
                    recipient=instance.cwsn_user,
                    notification_type='REQUEST_REJECTED',
                    title='Request Update',
                    message=f'Your request for {instance.service.title} was declined.',
                    content_object=instance
                )

# 3. Trigger for Reports (When a moderator takes action)
@receiver(pre_save, sender=Report)
def track_report_status_change(sender, instance, **kwargs):
    if instance.pk:
        try:
            old_instance = Report.objects.get(pk=instance.pk)
            instance._old_status = old_instance.status
        except Report.DoesNotExist:
            instance._old_status = None
    else:
        instance._old_status = None

@receiver(post_save, sender=Report)
def notify_on_report_action(sender, instance, created, **kwargs):
    if not created:
        old_status = getattr(instance, '_old_status', None)
        if old_status and old_status != instance.status and instance.status in ['Resolved', 'Dismissed']:
            Notification.objects.create(
                recipient=instance.reporter,
                notification_type='REPORT_UPDATE',
                title=f'Report {instance.status}',
                message=f'Moderators have reviewed your report against {instance.reported_user.email}. Status: {instance.status}.',
                content_object=instance
            )