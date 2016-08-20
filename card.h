#ifndef CARD_H
#define CARD_H

#include "strength.h"

class Card
{
public:
    Card();

private:
    QList<QRect>    provides;
    QList<Strength> requires;
};

#endif // CARD_H
