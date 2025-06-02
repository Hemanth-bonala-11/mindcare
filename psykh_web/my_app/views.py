from django.shortcuts import render, redirect
from django.contrib.auth import login, authenticate, logout
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.contrib.messages import get_messages

def index(request):
    return render(request, 'index.html')

@login_required
def chatroom(request):
    return render(request, 'chatroom.html')

def signup_view(request):
    if request.method == 'POST':
        form = UserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            messages.success(request, 'Account created successfully!')
            return redirect('index')
        else:
            for error in form.errors.values():
                messages.error(request, error)
    return render(request, 'signup.html')

def login_view(request):
    # Clear any existing messages
    storage = messages.get_messages(request)
    storage.used = True
    
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            messages.success(request, 'Logged in successfully!')
            return redirect('index')
        else:
            messages.error(request, 'Invalid username or password.')
    return render(request, 'login.html')

def logout_view(request):
    # Clear any existing messages
    storage = messages.get_messages(request)
    storage.used = True
    
    logout(request)
    messages.info(request, 'Logged out successfully!')
    return redirect('login')