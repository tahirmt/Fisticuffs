//  The MIT License (MIT)
//
//  Copyright (c) 2021 theScore Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import Quick
import Nimble
@testable import Fisticuffs

class SubscribableSpec: QuickSpec {
    override func spec() {
        describe("Subscribable") {
            var subject: FauxSubscribable<Int>!

            it("should perform callbacks using the given Scheduler") {
                let scheduler = FauxScheduler()
                let subscriptionOptions = SubscriptionOptions(receiveOn: scheduler)

                subject = FauxSubscribable()

                var disposable: Disposable?

                defer {
                    disposable?.dispose()
                }

                waitUntil { done in
                    disposable = subject.subscribe(subscriptionOptions) {
                        done()
                    }
                    subject.subscriptionCollection.notify(time: .afterChange, old: nil, new: 1)
                }

                expect(scheduler.scheduleCalled).to(beTrue())
            }
        }
    }
}

private class FauxSubscribable<Value>: Subscribable<Value> { }

private class FauxScheduler: Scheduler {
    private(set) var scheduleCalled = false

    func schedule(_ action: @escaping () -> Void) {
        scheduleCalled = true
        action()
    }
}
