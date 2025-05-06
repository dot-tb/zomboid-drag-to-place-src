---@class ExecuteCallbackAction: ISBaseTimedAction
---@field callback function
---@field validPredicate function|nil
ExecuteCallbackAction = ISBaseTimedAction:derive("ExecuteCallbackAction");

---Execute function even when queue is canceled
---@param character IsoPlayer
---@param callback function
---@param validPredicate function|nil
---@return ISBaseTimedAction
function ExecuteCallbackAction:new(character, callback, validPredicate)
    local o = ISBaseTimedAction.new(self, character);
    ---@type function
    o.callback = callback;
    o.validPredicate = validPredicate;
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    return o
end

function ExecuteCallbackAction:isValid()
    if not self.validPredicate then return true end;
    return self.validPredicate();
end

function ExecuteCallbackAction:start()
    self:callback();
    self:forceComplete();
end

function ExecuteCallbackAction:forceCancel()
    self.callback();
end
