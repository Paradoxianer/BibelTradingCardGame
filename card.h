#ifndef CARD_H
#define CARD_H

#include <QList>
#include <QRect>
#include <QString>

#include "strength.h"

class Card
{
public:
    Card();
    QString* Name(){return name;}
    QString* Verse(){return verse;}
    QString* Scripture(){return scripture;}

private:
    QList<QRect>    provides;
    QList<Strength> requires;
    QString*        name;
    QString*        verse;
    QString*        scripture;
};

#endif // CARD_H
