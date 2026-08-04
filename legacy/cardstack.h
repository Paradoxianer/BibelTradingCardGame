#ifndef CARDSTACK_H
#define CARDSTACK_H

#include <qlist.h>

class Card;

class CardStack
{
public:
    CardStack();
    ~CardStack();

    Card    *Draw(int where = 0);
    Card    *Insert(int where =0);
    void    Shuffel();

private:
    QList<Card> list;
};

#endif // CARDSTACK_H
