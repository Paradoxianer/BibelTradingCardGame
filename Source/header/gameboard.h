#ifndef GAMEBOARD_H
#define GAMEBOARD_H

#include "cardstack.h"
#include "deck.h"

#include <QList>

class GameBoard
{
public:
    GameBoard();
private:
    Deck                deck;
    QList<CardStack*>   slot;
    int                 closeToGod;
};

#endif // GAMEBOARD_H
