const std = @import("std");

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

const BoardSlot = struct {
    numOfSuroundingBombs: u8,
    isUncovered: bool,
    isBomb: bool,
};
var numBombs: u8 = 0;
var uncoveredSlots: u8 = 0;
var Board: [100]BoardSlot = .{initSlot()} ** (100);

pub fn main() !void {
    var firstMove = true;
    try addBombs();
    while (true) {
        try printBoard(true);

        const input = handleTurn();

        //have the first move not be loseable
        if (firstMove) {
            if (Board[input[1] * 10 + input[0]].isBomb) {
                Board[input[1] * 10 + input[0]].isBomb = false;
                numBombs -= 1;
            }
            //only adds the numbers after the first move to make sure they are accurate
            addNumbers();
            firstMove = false;
        }

        //uncover the selected input or
        if (!uncoverBoard(input)) {
            try gameOver();
            try printBoard(false);
            break;
        }

        //check for win condition
        if (uncoveredSlots == Board.len - numBombs) {
            try win();
            try printBoard(false);
            break;
        }
    }
}

fn addBombs() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const rand = prng.random();

    for (line) |row| {
        for (line) |column| {
            if (std.Random.intRangeAtMost(rand, u8, 0, 9) < 3) {
                Board[row * 10 + column].isBomb = true;
                numBombs += 1;
            }
        }
    }
}

fn addNumbers() void {
    for (line) |row| {
        for (line) |column| {
            if (Board[row * 10 + column].isBomb) continue;
            checkSurroundingsForBombs(row, column);
        }
    }
}

fn checkSurroundingsForBombs(row: u8, column: u8) void {
    for ([3]u8{ 255, 0, 1 }) |x| {
        const offsetX: u8 = @addWithOverflow(column, x)[0]; //index tuple to get result of addition
        if (offsetX > 9) {
            continue;
        }
        for ([3]u8{ 255, 0, 1 }) |y| {
            const offsetY: u8 = @addWithOverflow(row, y)[0]; //index tuple to get result of addition
            if (offsetY > 9) {
                continue;
            }
            if (Board[offsetY * 10 + offsetX].isBomb) {
                Board[row * 10 + column].numOfSuroundingBombs += 1;
            }
        }
    }
}

fn uncoverBoard(input: [2]u8) bool {
    const slot = Board[input[1] * 10 + input[0]];
    if (!slot.isUncovered) {
        Board[input[1] * 10 + input[0]].isUncovered = true;
        if (slot.isBomb) {
            return false;
        }
        uncoveredSlots += 1;
    }
    return true;
}

fn gameOver() !void {
    try stdout.print("GameOver\n", .{});
}

fn win() !void {
    try stdout.print("You Win :)\n", .{});
}

const line = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
fn printBoard(front: bool) !void {
    try stdout.print("   a b c d e f g h i j\n", .{});

    for (line) |row| {
        try stdout.print(" {d} ", .{row});
        for (line) |column| {
            const slot = Board[row * 10 + column];
            if (front and !slot.isUncovered) {
                try stdout.print("□ ", .{});
            } else {
                if (slot.isBomb) {
                    try stdout.print("Ó ", .{});
                } else {
                    try stdout.print("{d} ", .{slot.numOfSuroundingBombs});
                }
            }
        }
        try stdout.print("\n", .{});
    }
}

fn handleTurn() [2]u8 {
    if (handleInput()) |value| {
        if (convertInputToInts(value)) |cords| {
            return cords;
        } else |err| {
            std.log.debug("error found :{}", .{err});
            return handleTurn();
        }
    } else |err| {
        std.log.debug("error found :{}", .{err});
        return handleTurn();
    }
}
//97 > 106 48 > 57
fn convertInputToInts(input: [2]u8) ![2]u8 {
    const output = [2]u8{ @subWithOverflow(input[0], 97)[0], @subWithOverflow(input[1], 48)[0] }; //index tuple to get result of subtraction
    if ((output[0] > 9) or (output[1] > 9)) {
        return error.InvalidParam;
    } else {
        return output;
    }
}

fn handleInput() ![2]u8 {
    try stdout.print("input cordinates (a->j 0->9 ex: a0): ", .{});
    var buffer: [10]u8 = undefined;
    const input = try stdin.readUntilDelimiter(&buffer, '\n');
    return .{ input[0], input[1] };
}

fn initSlot() BoardSlot {
    return BoardSlot{
        .numOfSuroundingBombs = 0,
        .isBomb = false,
        .isUncovered = false,
    };
}
