#include "action.h"
#include "card.h"

Action::Action(Card *fromCard, Game *forGame)
{
    Init();
    universe    = forGame;
    source->append(fromCard);
}

void Action::Init()
{
    source      = new QList<Card>();
    target      = new QList<Card>();
    universe    = NULL;

}

void Action::AddSourceCard(Card *fromCard)
{
    source->append(fromCard);
}

void Action::RemoveSourceCard(Card *fromCard)
{
    int index=source->indexOf(fromCard);
    if (index>=0)
        source->removeAt(index);
}

void Action::AddTargetCard(Card *toCard)
{
    target->append(toCard);
}

void Action::RemoveTargetCard(Card *toCard)
{
    int index=target->indexOf(fromCard);
    if (index>=0)
        target->removeAt(index);
}
