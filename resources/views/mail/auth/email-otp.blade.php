<x-mail::message>
# Verify your email

Use the verification code below to {{ $actionText }} on SOUL.

<x-mail::panel>
# {{ $code }}
</x-mail::panel>

This code will expire in {{ $expiresInMinutes }} minutes.

For your security, do not share this code with anyone. SOUL support will
never ask you for your verification code.

If you did not request this code, you can safely ignore this email.

Thanks,<br>
SOUL
</x-mail::message>
