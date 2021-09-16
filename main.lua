-- Defines the blocks that indicate how a turtle should move.
left_turn_block = "minecraft:andesite"
right_turn_block = "minecraft:diorite"

-- Defines the blocks that indicate the start of a farm path. Start blocks also indicate the type of seed that should be planted in the farm.
start_blocks = {}

start_blocks["minecraft:birch_planks"] = {seed="minecraft:grass_seeds", crop="minecraft:wheat"}

-- Defines the blocks that indicate the end of a farm path. End blocks also indicate the type of seed that should be planted in the farm.
end_blocks = {}

end_blocks["minecraft:birch_stairs"] = {seed="minecraft:grass_seeds", crop="minecraft:wheat"}

-- Defines the total path length of the farm path.
-- This should be filled in when the farm is built.
farm_length = 999

-- Detection functions
function at_end()
  return start_blocks[turtle.inspectDown().name] ~= nil or end_blocks[turtle.inspectDown().name] ~= nil
end

-- Movement functions
function do_turn(block, is_in_reverse)
  if (block == left_turn_block and not is_in_reverse) or (block == right_turn_block and is_in_reverse) then
    turtle.turnLeft()
  else
    turtle.turnRight()
  end
end

-- TODO need to put select_item_with function here

-- Main event loop
function perform_farm_run()
  -- First, check to see if we even have enough fuel to perform the run.
  -- If we don't, log an error and return right away.
  if turtle.getFuelLevel() != "unlimited" or turtle.getFuelLevel() < farm_length then
    print("Error: insufficient fuel to complete farm run (Have " .. turtle.getFuelLevel() .. ", need " .. farm_length .. ")")
    return false
  end

  -- Next, check to see what seed type we should be using.
  local current_block = turtle.inspectDown().name
  local seed_to_plant = nil
  local crop_to_harvest = nil
  
  if start_blocks[current_block] ~= nil then
    seed_to_plant = start_blocks[current_block].seed
    crop_to_harvest = start_blocks[current_block].crop
  else
    seed_to_plant = end_blocks[current_block].seed
    crop_to_harvest = end_blocks[current_block].crop
  end

  -- Are we starting from the start block, or the end block?
  local is_in_reverse = end_blocks[current_block] ~= nil

  -- Move forward once to get started.
  turtle.forward()
  
  -- Start the farm loop.
  while not at_end() do
    -- Grab the current block name.
    current_block = turtle.inspectDown().name

    -- Are we on a special turn block, or just on a regular block?
    if current_block == left_turn_block or current_block == right_turn_block then
      -- Perform a turn.
      do_turn(current_block, is_in_reverse)
    else
      -- Otherwise, do some farming.

      -- First, check the left side.
      turtle.turnLeft()

      -- Is there a mature crop here? If so, dig it.
      local block_seen, seen_block = turtle.inspect()

      if seen_block.name == crop_to_harvest and seen_block.age == 7 then
        turtle.dig("left")
      end

      -- Check the space again. Is it empty?
      block_seen, seen_block = turtle.inspect()

      if not block_seen and select_slot_with(seed_to_plant) then
          turtle.place()
      end

      -- Attempt to harvest any items on this block.
      turtle.suck()

      -- Next, check the right side.
      turtle.turnRight()
      turtle.turnRight()

      -- Is there a mature crop here? If so, dig it.
      local block_seen, seen_block = turtle.inspect()

      if seen_block.name == crop_to_harvest and seen_block.state.age == 7 then
        turtle.dig("right")
      end

      -- Check the space again. Is it empty?
      block_seen, seen_block = turtle.inspect()

      if not block_seen and select_slot_with(seed_to_plant) then
          turtle.place()
      end

      -- Attempt to harvest any items on this block.
      turtle.suck()
    end

    -- Lastly, move forward.
    turtle.forward()
  end

  -- Dump all of the harvested crops into the chest behind the turtle until either we run out, or the chest becomes full.
  while select_slot_with(crop_to_harvest) do
    if not turtle.drop(1) then
      print("Chest is full!")
      break
    end
  end

  -- Do a 180 to reset position.
  turtle.turnLeft()
  turtle.turnLeft()

  -- Done!
end
