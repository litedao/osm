/// osm.sol - oracle security module

// Copyright (C) 2018  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.24;

import "ds-auth/auth.sol";
import "ds-stop/stop.sol";
// import "ds-value/value.sol";

interface DSValue {
    function peek() external returns (bytes32,bool);
    function read() external returns (bytes32);
}

contract OSM is DSAuth, DSStop {
    DSValue public src;
    
    uint16 constant ONE_HOUR = uint16(3600);

    uint16 public hop = ONE_HOUR;
    uint64 public zzz;

    struct Feed {
        uint128 val;
        bool    has;
    }

    Feed cur;
    Feed nxt;

    event LogValue(bytes32 val);
    
    constructor (DSValue src_) public {
        src = src_;
        (bytes32 wut, bool ok) = src_.peek();
        if (ok) {
            cur = nxt = Feed(uint128(wut), ok);
            zzz = prev(era());
        }
    }

    function era() internal view returns (uint) {
        return block.timestamp;
    }

    function prev(uint ts) internal view returns (uint64) {
        return uint64(ts - (ts % hop));
    }

    function step(uint16 ts) external auth {
        require(ts > 0);
        hop = ts;
    }

    function void() external auth {
        cur = nxt = Feed(0, false);
        stopped = true;
    }

    function pass() public view returns (bool ok) {
        return era() >= zzz + hop;
    }

    function poke() external stoppable {
        require(pass());
        (bytes32 wut, bool ok) = src.peek();
        cur = nxt;
        nxt = Feed(uint128(wut), ok);
        zzz = prev(era());
        emit LogValue(bytes32(cur.val));
    }

    function peek() external view returns (bytes32,bool) {
        return (bytes32(cur.val), cur.has);
    }

    function peep() external view returns (bytes32,bool) {
        return (bytes32(nxt.val), nxt.has);
    }

    function read() external view returns (bytes32) {
        require(cur.has);
        return (bytes32(cur.val));
    }
}
