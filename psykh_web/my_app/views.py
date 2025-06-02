from django.shortcuts import render, redirect


def home(request):
    return render(request,"index.html")

def chatroom(request):
    return render(request,"chatroom.html")