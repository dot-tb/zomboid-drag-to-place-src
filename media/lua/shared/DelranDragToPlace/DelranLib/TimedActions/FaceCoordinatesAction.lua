---@type ISBaseTimedAction
FaceCoordinatesAction = ISBaseTimedAction:derive("FaceCoordinatesAction")

function FaceCoordinatesAction:isValid()
    return true;
end

function FaceCoordinatesAction:start()
    self.character:faceLocationF(self.x, self.y);
end

function FaceCoordinatesAction:update()
    if not self.character:shouldBeTurning() then
        self:perform()
    end;
end

function FaceCoordinatesAction:perform()
    ISBaseTimedAction.perform(self);
end

function FaceCoordinatesAction:new(character, x, y)
    local o = ISBaseTimedAction.new(self, character);
    self.x = x;
    self.y = y;
    return o
end
