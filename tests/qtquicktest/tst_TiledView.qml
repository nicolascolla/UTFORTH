/*
 * Copyright (C) 2017 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored-by: Florian Boucault <florian.boucault@canonical.com>
 */

import QtQuick 2.4
import QtTest 1.0
import "../../src/app/qml"

TestCase {
    name: "TiledView"

    TiledView {
        id: tiledView
        width: 800
        height: 600
    }

    property Component objectComponent: Rectangle {
        width: 100
        height: 50
        color: "red"
    }

    SignalSpy {
        id: countSpy
        target: tiledView
        signalName: "countChanged"
    }

    function init() {
        countSpy.clear();
    }

    function test_defaults() {
        compare(tiledView.count, 0);
    }

    function test_setRootItemValid() {
        var newObject = objectComponent.createObject(tiledView);
        var oldRoot = tiledView.setRootItem(newObject);
        compare(oldRoot, null);
        compare(countSpy.count, 1);
        compare(tiledView.count, 1);
        compare(newObject.width, tiledView.width);
        compare(newObject.height, tiledView.height);
        compare(tiledView.getOrientation(newObject), Qt.Horizontal);
        tiledView.setRootItem(null);
        newObject.destroy();
    }

    function test_setRootItemNull() {
        var oldRoot = tiledView.setRootItem(null);
        compare(oldRoot, null);
        compare(countSpy.count, 0);
        compare(tiledView.count, 0);
    }

    function test_resetRootItem() {
        // set to new object
        var newObject = objectComponent.createObject(tiledView);
        var oldRoot = tiledView.setRootItem(newObject);
        compare(oldRoot, null);
        compare(countSpy.count, 1);
        compare(tiledView.count, 1);

        // set to same object
        oldRoot = tiledView.setRootItem(newObject);
        compare(oldRoot, null);
        compare(countSpy.count, 1);
        compare(tiledView.count, 1);

        // set to another new object
        var newObject2 = objectComponent.createObject(tiledView);
        oldRoot = tiledView.setRootItem(newObject2);
        compare(oldRoot, newObject);
        compare(countSpy.count, 1);
        compare(tiledView.count, 1);

        // set to null
        oldRoot = tiledView.setRootItem(null);
        compare(oldRoot, newObject2);
        compare(countSpy.count, 2);
        compare(tiledView.count, 0);

        newObject.destroy();
        newObject2.destroy();
    }

    function verifySetRootItem(object) {
        tiledView.setRootItem(object);
        compare(tiledView.count, 1);
        compare(object.width, tiledView.width);
        compare(object.height, tiledView.height);
    }

    function verifySetOrientation(object, orientation) {
        tiledView.setOrientation(object, orientation);
        compare(tiledView.getOrientation(object), orientation);
    }

    function verifyAdd(object, newObject, side) {
        var previousX = object.x;
        var previousY = object.y;
        var previousWidth = object.width;
        var previousHeight = object.height;
        var previousCount = tiledView.count;
        var orientation = tiledView.getOrientation(object);

        tiledView.add(object, newObject, side);
        compare(tiledView.count, previousCount+1);
        compare(tiledView.getOrientation(object), Qt.Horizontal);
        compare(tiledView.getOrientation(newObject), Qt.Horizontal);

        if (orientation == Qt.Horizontal) {
            compare(object.width, previousWidth / 2);
            compare(object.height, previousHeight);
            compare(newObject.width, previousWidth / 2);
            compare(newObject.height, previousHeight);
            if (side == Qt.AlignTrailing) {
                compare(object.x, previousX);
                compare(object.y, previousY);
                compare(newObject.x, previousX + Math.round(previousWidth / 2));
                compare(newObject.y, previousY);
            } else if (side == Qt.AlignLeading) {
                compare(newObject.x, previousX);
                compare(newObject.y, previousY);
                compare(object.x, previousX + Math.round(previousWidth / 2));
                compare(object.y, previousY);
            }
        } else if (orientation == Qt.Vertical) {
            compare(object.width, previousWidth);
            compare(object.height, previousHeight / 2);
            compare(newObject.width, previousWidth);
            compare(newObject.height, previousHeight / 2);
            if (side == Qt.AlignTrailing) {
                compare(object.x, previousX);
                compare(object.y, previousY);
                compare(newObject.x, previousX);
                compare(newObject.y, previousY + Math.round(previousHeight / 2));
            } else if (side == Qt.AlignLeading) {
                compare(newObject.x, previousX);
                compare(newObject.y, previousY);
                compare(object.x, previousX);
                compare(object.y, previousY + Math.round(previousHeight / 2));
            }
        }
    }

    function verifyRemove(object) {
        var node = tiledView.__rootNode.findNodeWithValue(object);
        var siblingNode = node.getSibling();
        var siblingObject = siblingNode.value;

        var side;
        if (node.parent.left === node) {
            side = Qt.AlignLeading;
        } else {
            side = Qt.AlignTrailing;
        }
        var orientation = node.parent.orientation;

        var expectedX;
        var expectedY;
        var expectedWidth;
        var expectedHeight;
        if (orientation == Qt.Horizontal) {
            expectedWidth = object.width + siblingNode.width;
            expectedHeight = siblingNode.height;
            if (side == Qt.AlignTrailing) {
                expectedX = siblingNode.x;
                expectedY = siblingNode.y;
            } else if (side == Qt.AlignLeading) {
                expectedX = object.x;
                expectedY = siblingNode.y;
            }
        } else if (orientation == Qt.Vertical) {
            expectedWidth = siblingNode.width;
            expectedHeight = object.height + siblingNode.height;
            if (side == Qt.AlignTrailing) {
                expectedX = siblingNode.x;
                expectedY = siblingNode.y;
            } else if (side == Qt.AlignLeading) {
                expectedX = siblingNode.x;
                expectedY = object.y;
            }
        }

        var previousCount = tiledView.count;

        tiledView.remove(object);
        // TODO: we verify that the resulting node has the correct x/y,width/height
        // but we could go further and verify that all its children also do
        var removeNode = tiledView.__rootNode.findNodeWithValue(siblingObject);
        compare(tiledView.count, previousCount-1);
        compare(removeNode.width, expectedWidth);
        compare(removeNode.height, expectedHeight);
        compare(removeNode.x, expectedX);
        compare(removeNode.y, expectedY);
    }

    function test_simpleAdd_data() {
        return [
                    {orientation: Qt.Horizontal, side: Qt.AlignTrailing},
                    {orientation: Qt.Vertical, side: Qt.AlignTrailing},
                    {orientation: Qt.Horizontal, side: Qt.AlignLeading},
                    {orientation: Qt.Vertical, side: Qt.AlignLeading},
        ];
    }

    function test_simpleAdd(data) {
        var rootObject = objectComponent.createObject(tiledView);
        verifySetRootItem(rootObject);
        verifySetOrientation(rootObject, data.orientation);

        var newObject = objectComponent.createObject(tiledView);
        verifyAdd(rootObject, newObject, data.side);

        tiledView.setRootItem(null);
        rootObject.destroy();
        newObject.destroy();
    }

    function test_nestedAdds() {
        var objects = [];

        objects["0"] = objectComponent.createObject(tiledView);
        verifySetRootItem(objects["0"]);

        objects["1"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["0"], Qt.Horizontal);
        verifyAdd(objects["0"], objects["1"], Qt.AlignTrailing);

        objects["2"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["1"], Qt.Horizontal);
        verifyAdd(objects["1"], objects["2"], Qt.AlignTrailing);

        objects["3"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["2"], Qt.Horizontal);
        verifyAdd(objects["2"], objects["3"], Qt.AlignTrailing);

        objects["4"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["3"], Qt.Horizontal);
        verifyAdd(objects["3"], objects["4"], Qt.AlignTrailing);

        objects["5"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["4"], Qt.Horizontal);
        verifyAdd(objects["4"], objects["5"], Qt.AlignTrailing);

        objects["6"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["5"], Qt.Horizontal);
        verifyAdd(objects["5"], objects["6"], Qt.AlignTrailing);

        tiledView.setRootItem(null);
        for (var i=0; i<objects.length; i++) {
            objects[i].destroy();
        }
    }

    function test_resizeView() {
        var leftObject = objectComponent.createObject(tiledView);
        verifySetRootItem(leftObject);

        var bottomRightObject = objectComponent.createObject(tiledView);
        verifySetOrientation(leftObject, Qt.Horizontal);
        verifyAdd(leftObject, bottomRightObject, Qt.AlignTrailing);

        var topRightObject = objectComponent.createObject(tiledView);
        verifySetOrientation(bottomRightObject, Qt.Vertical);
        verifyAdd(bottomRightObject, topRightObject, Qt.AlignLeading);

        var initialWidth = tiledView.width;
        var initialHeight = tiledView.height;
        var factor = 0.7;

        // storing sizes before resizing
        var sizes = {"leftObject": {"width": leftObject.width, "height": leftObject.height},
                     "bottomRightObject": {"width": bottomRightObject.width, "height": bottomRightObject.height},
                     "topRightObject": {"width": topRightObject.width, "height": topRightObject.height}};
        tiledView.width = initialWidth * factor;
        compare(leftObject.width, sizes.leftObject.width * factor);
        compare(bottomRightObject.width, sizes.bottomRightObject.width * factor);
        compare(topRightObject.width, sizes.topRightObject.width * factor);
        compare(leftObject.height, sizes.leftObject.height);
        compare(bottomRightObject.height, sizes.bottomRightObject.height);
        compare(topRightObject.height, sizes.topRightObject.height);

        tiledView.height = initialHeight * factor;
        compare(leftObject.width, sizes.leftObject.width * factor);
        compare(bottomRightObject.width, sizes.bottomRightObject.width * factor);
        compare(topRightObject.width, sizes.topRightObject.width * factor);
        compare(leftObject.height, sizes.leftObject.height * factor);
        compare(bottomRightObject.height, sizes.bottomRightObject.height * factor);
        compare(topRightObject.height, sizes.topRightObject.height * factor);

        // resetting initial size
        tiledView.width = initialWidth;
        tiledView.height = initialHeight;
        compare(leftObject.width, sizes.leftObject.width);
        compare(bottomRightObject.width, sizes.bottomRightObject.width);
        compare(topRightObject.width, sizes.topRightObject.width);
        compare(leftObject.height, sizes.leftObject.height);
        compare(bottomRightObject.height, sizes.bottomRightObject.height);
        compare(topRightObject.height, sizes.topRightObject.height);

        tiledView.setRootItem(null);
        leftObject.destroy();
        bottomRightObject.destroy();
        topRightObject.destroy();
    }

    function test_simpleRemove_data() {
        return [
                    {orientation: Qt.Horizontal, side: Qt.AlignTrailing},
                    {orientation: Qt.Vertical, side: Qt.AlignTrailing},
                    {orientation: Qt.Horizontal, side: Qt.AlignLeading},
                    {orientation: Qt.Vertical, side: Qt.AlignLeading},
        ];
    }

    function test_simpleRemove(data) {
        var rootObject = objectComponent.createObject(tiledView);
        verifySetRootItem(rootObject);
        verifySetOrientation(rootObject, data.orientation);

        var newObject = objectComponent.createObject(tiledView);
        verifyAdd(rootObject, newObject, data.side);
        verifyRemove(newObject);

        verifyAdd(rootObject, newObject, data.side);
        verifyRemove(rootObject);

        verifyAdd(newObject, rootObject, data.side);
        verifyRemove(newObject);

        tiledView.setRootItem(null);
        rootObject.destroy();
        newObject.destroy();
    }

    function test_nestedAddsRemoveRoot() {
        var objects = [];

        objects["0"] = objectComponent.createObject(tiledView);
        verifySetRootItem(objects["0"]);

        objects["1"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["0"], Qt.Horizontal);
        verifyAdd(objects["0"], objects["1"], Qt.AlignTrailing);

        objects["2"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["1"], Qt.Horizontal);
        verifyAdd(objects["1"], objects["2"], Qt.AlignTrailing);

        // remove root
        verifyRemove(objects["0"]);

        // add further
        objects["3"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["2"], Qt.Horizontal);
        verifyAdd(objects["2"], objects["3"], Qt.AlignTrailing);

        verifyRemove(objects["2"]);

        objects["4"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["1"], Qt.Horizontal);
        verifyAdd(objects["1"], objects["4"], Qt.AlignTrailing);

        verifyRemove(objects["1"]);

        tiledView.setRootItem(null);
        for (var i=0; i<objects.length; i++) {
            objects[i].destroy();
        }
    }

    function test_AddsVertical() {
        var objects = [];

        objects["0"] = objectComponent.createObject(tiledView);
        verifySetRootItem(objects["0"]);

        objects["1"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["0"], Qt.Vertical);
        verifyAdd(objects["0"], objects["1"], Qt.AlignTrailing);

        objects["2"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["1"], Qt.Vertical);
        verifyAdd(objects["1"], objects["2"], Qt.AlignTrailing);

        objects["3"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["2"], Qt.Vertical);
        verifyAdd(objects["2"], objects["3"], Qt.AlignLeading);

        objects["4"] = objectComponent.createObject(tiledView);
        verifySetOrientation(objects["3"], Qt.Vertical);
        verifyAdd(objects["3"], objects["4"], Qt.AlignTrailing);

        tiledView.setRootItem(null);
        for (var i=0; i<objects.length; i++) {
            objects[i].destroy();
        }
    }
}
