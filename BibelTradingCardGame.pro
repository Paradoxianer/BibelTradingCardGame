#-------------------------------------------------
#
# Project created by QtCreator 2016-08-15T20:42:19
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = BibelTradingCardGames
TEMPLATE = app


SOURCES +=  Source/src/main.cpp\
    Source/src/mainwindow.cpp \
    Source/src/card.cpp \
    Source/src/deck.cpp \
    Source/src/cardboard.cpp \
    Source/src/game.cpp \
    Source/src/cardstack.cpp \
    Source/src/strength.cpp \
    Source/src/action.cpp \
    Source/src/player.cpp \
    Source/src/gameboard.cpp

HEADERS  += Source/header/mainwindow.h \
    Source/header/card.h \
    Source/header/deck.h \
    Source/header/cardboard.h \
    Source/header/game.h \
    Source/header/cardstack.h \
    Source/header/strength.h \
    Source/header/action.h \
    Source/header/player.h \
    Source/header/gameboard.h \
    Source/header/gamedefs.h

FORMS    += Source/mainwindow.ui

DISTFILES += \
    LICENSE \
    README.md
