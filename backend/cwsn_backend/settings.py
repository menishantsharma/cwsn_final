"""
Django settings for cwsn_backend project.
Generated for Production and Docker Environments.
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# ==============================================================================
# CORE SECURITY & ENVIRONMENT SETTINGS
# ==============================================================================
# SECRET_KEY falls back to a dummy key ONLY if the environment variable is missing
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-local-dev-key-change-me')

# Never run with DEBUG = True in production!
DEBUG = os.environ.get('DEBUG', 'False') == 'True'

# Allow incoming traffic from your Nginx proxy and your specific IP/Domain
# Example format in .env: ALLOWED_HOSTS=127.0.0.1,localhost,10.129.7.48
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '127.0.0.1,localhost').split(',')
# Force Django to accept absolutely all incoming connections
# ALLOWED_HOSTS = ['*']
# ADD THIS LINE: Explicitly trust the origins for CSRF validation
CSRF_TRUSTED_ORIGINS = os.environ.get('CSRF_TRUSTED_ORIGINS', 'http://localhost:9000').split(',')
# ==============================================================================
# APPLICATION DEFINITION
# ==============================================================================
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Note: 'django.contrib.sites' is completely removed as we don't use allauth

    # Third-Party Apps
    'rest_framework',
    'rest_framework.authtoken',
    'django_filters',

    # Custom Local Apps
    'apps.users.apps.UsersConfig',
    'apps.common.apps.CommonConfig',
    'apps.services.apps.ServicesConfig',
    'apps.interactions.apps.InteractionsConfig',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'cwsn_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'cwsn_backend.wsgi.application'


# ==============================================================================
# DATABASE & CACHE SETTINGS
# ==============================================================================
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'cwsn_db'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'pass123'),
        'HOST': os.environ.get('DB_HOST', 'db'), # Defaults to the Docker service name 'db'
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

# Using django-redis backend to support wildcard cache invalidation (delete_pattern)
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': os.environ.get('REDIS_URL', 'redis://redis:6379/1'), # Defaults to Docker 'redis'
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}


# ==============================================================================
# AUTHENTICATION & USERS
# ==============================================================================
# Pointing to our custom User model which uses phone_number
AUTH_USER_MODEL = 'users.User'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',},
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ],
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend'
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10,
}


# ==============================================================================
# TWILIO API SETTINGS
# ==============================================================================
TWILIO_ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID', '')
TWILIO_AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN', '')
TWILIO_VERIFY_SERVICE_SID = os.environ.get('TWILIO_VERIFY_SERVICE_SID', '')


# ==============================================================================
# INTERNATIONALIZATION
# ==============================================================================
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kolkata' # --- CHANGED FROM 'UTC' ---
USE_I18N = True
USE_TZ = True


# ==============================================================================
# STATIC & MEDIA FILES (For Docker/Nginx Integration)
# ==============================================================================
# Static files (CSS, JavaScript, Images for the Admin Panel)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Media files (Files/Images uploaded by the end users)
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# ==============================================================================
# THIRD-PARTY WIDGETS
# ==============================================================================
GIS_WIDGET_LIBRARIES = {
    'openstreetmap': {
        'js': ['https://cdnjs.cloudflare.com/ajax/libs/openlayers/4.6.5/ol.js'],
        'css': ['https://cdnjs.cloudflare.com/ajax/libs/openlayers/4.6.5/ol.css'],
    }
}
