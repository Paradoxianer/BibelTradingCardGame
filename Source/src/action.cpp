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
