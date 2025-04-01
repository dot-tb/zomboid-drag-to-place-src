DelranDragToPlace = {};

DelranDragToPlace.OnDragItem = function(item, playerNum)
    print("HAHA DRAGIN THIS : ", item);
end

Events.SetDragItem.Add(DelranDragToPlace.OnDragItem);
