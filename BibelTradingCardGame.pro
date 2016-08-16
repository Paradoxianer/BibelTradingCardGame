#-------------------------------------------------
#
# Project created by QtCreator 2016-08-15T20:42:19
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = BibelTradingCardGames
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp \
    card.cpp \
    deck.cpp \
    cardboard.cpp \
    game.cpp

HEADERS  += mainwindow.h \
    card.h \
    deck.h \
    cardboard.h \
    game.h

FORMS    += mainwindow.ui

DISTFILES += \
    LICENSE \
    README.md
