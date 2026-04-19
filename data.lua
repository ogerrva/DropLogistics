local drop_zone = table.deepcopy(data.raw["container"]["wooden-chest"])
drop_zone.name = "logistic-drop-zone"
drop_zone.minable.result = "logistic-drop-zone"
drop_zone.inventory_size = 1

drop_zone.collision_box = {{0, 0}, {0, 0}}
drop_zone.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}

local drop_zone_item = table.deepcopy(data.raw["item"]["wooden-chest"])
drop_zone_item.name = "logistic-drop-zone"
drop_zone_item.place_result = "logistic-drop-zone"
drop_zone_item.order = "a[items]-c[logistic-drop-zone]"

local drop_zone_recipe = table.deepcopy(data.raw["recipe"]["wooden-chest"])
drop_zone_recipe.name = "logistic-drop-zone"
drop_zone_recipe.results = {{type="item", name="logistic-drop-zone", amount=1}}
drop_zone_recipe.ingredients = {{type="item", name="wood", amount=1}}

data:extend{drop_zone, drop_zone_item, drop_zone_recipe}