/// delay.t.sol - tests for delay.sol

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

pragma solidity ^0.4.20;

import "ds-test/test.sol";

import "./delay.sol";

contract TestUser {

    function doPoke(DSDelay delay) public {
        delay.poke();
    }
}

contract DSDelayTest is DSTest {
    DSDelay delay;
    DSValue v;

    function setUp() public {
        v = new DSValue();
    }

    function log(DSDelay d) public {
        bytes32 val; bool has;
        (val, has) = d.peek();
        uint nxt = uint(d.nxt());
        uint zzz = uint(d.zzz());
        log_bytes32("------");
        log_named_uint("val", uint(val));
        log_named_uint("nxt", nxt);
        log_named_uint("zzz", zzz);
    }

    function testFailReadOnEmptyValue() public {
        delay = new DSDelay(v);
        delay.read();
    }

    function testPeekOnEmptyValue() public {
        delay = new DSDelay(v);
        bytes32 val; bool ok;
        (val, ok) = delay.peek();

        assertEq(val, 0);
        assertTrue(!ok);
    }

    function testCreation() public {
        bytes32 val = 1;
        v.poke(val);
        
        assertEq(v.read(), val);
        
        delay = new DSDelay(v);

        assertEq(delay.read(), val);
        assertEq(delay.nxt(), val);        
    }

    function testUserCanPoke() public {
        TestUser u = new TestUser();
        v.poke(1);
        delay = new DSDelay(v);

        delay.warp(1 hours);

        u.doPoke(delay);
    }

    function testValueUnchangedBeforeOneHour() public {
        bytes32 val = 1;
        v.poke(val);
        delay = new DSDelay(v);

        assertEq(delay.read(), val);
        assertEq(delay.nxt(), val);

        v.poke(2);

        delay.warp(30 minutes);

        bool success = delay.poke();

        assertTrue(!success);
        assertEq(delay.read(), val);
        assertEq(delay.nxt(), val);
    }

    function testNextValueChangedAfterOneHour() public {
        bytes32 val = 1;
        v.poke(val);
        delay = new DSDelay(v);

        assertEq(delay.read(), val);
        assertEq(delay.nxt(), val);

        v.poke(2);
        
        delay.warp(1 hours);

        bool success = delay.poke();

        // Current value reads 1, but next value is 2
        assertTrue(success);
        assertEq(delay.read(), val);
        assertEq(delay.nxt(), 2);

        v.poke(3);
        
        delay.warp(1 hours);

        success = delay.poke();

        // Current value reads 2, but next value is 3
        assertTrue(success);
        assertEq(delay.read(), 2);
        assertEq(delay.nxt(), 3);

        delay.warp(1 hours);

        success = delay.poke();

        // Current value reads 3, next value still 3
        assertTrue(success);
        assertEq(delay.read(), 3);
        assertEq(delay.nxt(), 3);
    }
}